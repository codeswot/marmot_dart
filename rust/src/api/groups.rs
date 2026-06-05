use mdk_core::extension::group_image::{decrypt_group_image, prepare_group_image_for_upload};
use mdk_core::groups::{NostrGroupConfigData, NostrGroupDataUpdate};
use mdk_core::MDK;
use mdk_storage_traits::groups::types::Group;
use mdk_storage_traits::{MdkStorageProvider, Secret};
use nostr::{EventId, JsonUtil, ToBech32, UnsignedEvent};

use crate::api::error::MarmotError;
use crate::convert::{
    group_id_from_hex, group_id_hex, parse_events, parse_pubkey, parse_relays, pubkey_npub,
    unsigned_events_to_json,
};
use crate::state;

fn bytes_to_array<const N: usize>(bytes: &[u8], field: &str) -> Result<[u8; N], MarmotError> {
    bytes
        .try_into()
        .map_err(|_| MarmotError::Media(format!("{field} must be {N} bytes")))
}

pub struct CreateGroupParams {
    pub name: String,
    pub description: String,
    pub relay_urls: Vec<String>,
    pub member_key_package_event_jsons: Vec<String>,
}

pub struct GroupCreateResult {
    pub group: MarmotGroup,
    pub welcome_rumors: Vec<String>,
}

pub struct MarmotGroup {
    pub id: String,
    pub nostr_group_id: String,
    pub name: String,
    pub description: String,
    pub relay_urls: Vec<String>,
    pub admin_npubs: Vec<String>,
    pub member_count: u32,
    pub image_hash: Option<Vec<u8>>,
    pub image_key: Option<Vec<u8>>,
    pub image_nonce: Option<Vec<u8>>,
}

pub struct GroupMetadataUpdate {
    pub name: Option<String>,
    pub description: Option<String>,
    pub relay_urls: Option<Vec<String>>,
    pub admin_npubs: Option<Vec<String>>,
}

pub struct GroupImagePrepared {
    pub encrypted_data: Vec<u8>,
    pub image_hash: Vec<u8>,
    pub image_key: Vec<u8>,
    pub image_nonce: Vec<u8>,
    pub image_upload_key: Vec<u8>,
    pub upload_nsec: String,
    pub upload_pubkey_hex: String,
    pub mime_type: String,
    pub blurhash: Option<String>,
    pub thumbhash: Option<String>,
    pub dimensions_width: Option<u32>,
    pub dimensions_height: Option<u32>,
}

pub struct MarmotMember {
    pub npub: String,
    pub pubkey_hex: String,
}

pub struct PendingWelcome {
    pub id: String,
    pub group_name: String,
    pub inviter_npub: String,
    pub member_count: u32,
}

pub struct MemberChangeResult {
    pub evolution_event_json: String,
    pub welcome_rumors: Vec<String>,
}

pub fn create(
    db_path: String,
    creator_npub: String,
    params: CreateGroupParams,
) -> Result<GroupCreateResult, MarmotError> {
    let creator = parse_pubkey(&creator_npub)?;
    let relays = parse_relays(&params.relay_urls)?;
    let member_events = parse_events(&params.member_key_package_event_jsons)?;
    state::with_state(&db_path, |s| {
        let config = NostrGroupConfigData::new(
            params.name,
            params.description,
            None,
            None,
            None,
            relays,
            vec![creator],
        );
        let result = s.mdk.create_group(&creator, member_events, config)?;
        let group_id = result.group.mls_group_id.clone();
        s.mdk.merge_pending_commit(&group_id)?;
        Ok(GroupCreateResult {
            group: group_dto(&s.mdk, &result.group)?,
            welcome_rumors: unsigned_events_to_json(&result.welcome_rumors),
        })
    })
}

pub fn process_welcome(
    db_path: String,
    wrapper_event_id: String,
    welcome_rumor_json: String,
) -> Result<(), MarmotError> {
    let event_id =
        EventId::from_hex(&wrapper_event_id).map_err(|e| MarmotError::InvalidEvent(e.to_string()))?;
    let rumor = UnsignedEvent::from_json(&welcome_rumor_json)
        .map_err(|e| MarmotError::InvalidEvent(e.to_string()))?;
    state::with_state(&db_path, |s| {
        s.mdk.process_welcome(&event_id, &rumor)?;
        Ok(())
    })
}

pub fn get_pending_welcomes(db_path: String) -> Result<Vec<PendingWelcome>, MarmotError> {
    state::with_state(&db_path, |s| {
        s.mdk
            .get_pending_welcomes(None)?
            .iter()
            .map(|w| {
                Ok(PendingWelcome {
                    id: w.id.to_hex(),
                    group_name: w.group_name.clone(),
                    inviter_npub: pubkey_npub(&w.welcomer)?,
                    member_count: w.member_count,
                })
            })
            .collect()
    })
}

pub fn accept_welcome(db_path: String, welcome_id: String) -> Result<(), MarmotError> {
    let event_id =
        EventId::from_hex(&welcome_id).map_err(|e| MarmotError::InvalidEvent(e.to_string()))?;
    state::with_state(&db_path, |s| {
        let welcome = s
            .mdk
            .get_welcome(&event_id)?
            .ok_or(MarmotError::WelcomeNotFound)?;
        s.mdk.accept_welcome(&welcome)?;
        Ok(())
    })
}

pub fn list(db_path: String) -> Result<Vec<MarmotGroup>, MarmotError> {
    state::with_state(&db_path, |s| {
        s.mdk
            .get_groups()?
            .iter()
            .map(|g| group_dto(&s.mdk, g))
            .collect()
    })
}

pub fn get_members(db_path: String, group_id: String) -> Result<Vec<MarmotMember>, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    state::with_state(&db_path, |s| {
        s.mdk
            .get_members(&gid)?
            .iter()
            .map(|pk| {
                Ok(MarmotMember {
                    npub: pubkey_npub(pk)?,
                    pubkey_hex: pk.to_hex(),
                })
            })
            .collect()
    })
}

pub fn add_member(
    db_path: String,
    group_id: String,
    key_package_event_json: String,
) -> Result<MemberChangeResult, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    let events = parse_events(&[key_package_event_json])?;
    state::with_state(&db_path, |s| {
        let result = s.mdk.add_members(&gid, &events)?;
        s.mdk.merge_pending_commit(&gid)?;
        Ok(member_change_dto(result))
    })
}

pub fn remove_member(
    db_path: String,
    group_id: String,
    npub: String,
) -> Result<MemberChangeResult, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    let pubkey = parse_pubkey(&npub)?;
    state::with_state(&db_path, |s| {
        let result = s.mdk.remove_members(&gid, &[pubkey])?;
        s.mdk.merge_pending_commit(&gid)?;
        Ok(member_change_dto(result))
    })
}

pub fn update_group_metadata(
    db_path: String,
    group_id: String,
    update: GroupMetadataUpdate,
) -> Result<String, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    let relays = match update.relay_urls {
        Some(urls) => Some(parse_relays(&urls)?),
        None => None,
    };
    let admins = match update.admin_npubs {
        Some(npubs) => Some(
            npubs
                .iter()
                .map(|n| parse_pubkey(n))
                .collect::<Result<Vec<_>, _>>()?,
        ),
        None => None,
    };
    state::with_state(&db_path, |s| {
        let result = s.mdk.update_group_data(
            &gid,
            NostrGroupDataUpdate {
                name: update.name,
                description: update.description,
                relays,
                admins,
                ..Default::default()
            },
        )?;
        s.mdk.merge_pending_commit(&gid)?;
        Ok(result.evolution_event.as_json())
    })
}

pub fn prepare_group_image(
    image_data: Vec<u8>,
    mime_type: String,
) -> Result<GroupImagePrepared, MarmotError> {
    let upload = prepare_group_image_for_upload(&image_data, &mime_type)
        .map_err(|e| MarmotError::Media(e.to_string()))?;
    Ok(GroupImagePrepared {
        encrypted_data: upload.encrypted_data.as_ref().clone(),
        image_hash: upload.encrypted_hash.to_vec(),
        image_key: upload.image_key.as_ref().to_vec(),
        image_nonce: upload.image_nonce.as_ref().to_vec(),
        image_upload_key: upload.image_upload_key.as_ref().to_vec(),
        upload_nsec: upload
            .upload_keypair
            .secret_key()
            .to_bech32()
            .map_err(|e| MarmotError::Media(e.to_string()))?,
        upload_pubkey_hex: upload.upload_keypair.public_key().to_hex(),
        mime_type: upload.mime_type,
        blurhash: upload.blurhash,
        thumbhash: upload.thumbhash,
        dimensions_width: upload.dimensions.map(|d| d.0),
        dimensions_height: upload.dimensions.map(|d| d.1),
    })
}

pub fn set_group_image(
    db_path: String,
    group_id: String,
    image_hash: Vec<u8>,
    image_key: Vec<u8>,
    image_nonce: Vec<u8>,
    image_upload_key: Vec<u8>,
) -> Result<String, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    let hash: [u8; 32] = bytes_to_array(&image_hash, "image_hash")?;
    let key: [u8; 32] = bytes_to_array(&image_key, "image_key")?;
    let nonce: [u8; 12] = bytes_to_array(&image_nonce, "image_nonce")?;
    let upload_key: [u8; 32] = bytes_to_array(&image_upload_key, "image_upload_key")?;
    state::with_state(&db_path, |s| {
        let result = s.mdk.update_group_data(
            &gid,
            NostrGroupDataUpdate {
                image_hash: Some(Some(hash)),
                image_key: Some(Some(key)),
                image_nonce: Some(Some(nonce)),
                image_upload_key: Some(Some(upload_key)),
                ..Default::default()
            },
        )?;
        s.mdk.merge_pending_commit(&gid)?;
        Ok(result.evolution_event.as_json())
    })
}

pub fn clear_group_image(db_path: String, group_id: String) -> Result<String, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    state::with_state(&db_path, |s| {
        let result = s.mdk.update_group_data(
            &gid,
            NostrGroupDataUpdate {
                image_hash: Some(None),
                ..Default::default()
            },
        )?;
        s.mdk.merge_pending_commit(&gid)?;
        Ok(result.evolution_event.as_json())
    })
}

pub fn decrypt_group_image_blob(
    encrypted_data: Vec<u8>,
    image_hash: Vec<u8>,
    image_key: Vec<u8>,
    image_nonce: Vec<u8>,
) -> Result<Vec<u8>, MarmotError> {
    let hash: [u8; 32] = bytes_to_array(&image_hash, "image_hash")?;
    let key = Secret::new(bytes_to_array::<32>(&image_key, "image_key")?);
    let nonce = Secret::new(bytes_to_array::<12>(&image_nonce, "image_nonce")?);
    decrypt_group_image(&encrypted_data, Some(&hash), &key, &nonce)
        .map_err(|e| MarmotError::Media(e.to_string()))
}

pub(crate) fn group_dto<S: MdkStorageProvider>(
    mdk: &MDK<S>,
    group: &Group,
) -> Result<MarmotGroup, MarmotError> {
    let relay_urls = mdk
        .get_relays(&group.mls_group_id)?
        .iter()
        .map(|r| r.to_string())
        .collect();
    let admin_npubs = group
        .admin_pubkeys
        .iter()
        .map(pubkey_npub)
        .collect::<Result<Vec<_>, _>>()?;
    let member_count = mdk.get_members(&group.mls_group_id)?.len() as u32;
    Ok(MarmotGroup {
        id: group_id_hex(&group.mls_group_id),
        nostr_group_id: hex::encode(group.nostr_group_id),
        name: group.name.clone(),
        description: group.description.clone(),
        relay_urls,
        admin_npubs,
        member_count,
        image_hash: group.image_hash.map(|h| h.to_vec()),
        image_key: group.image_key.as_ref().map(|k| k.as_ref().to_vec()),
        image_nonce: group.image_nonce.as_ref().map(|n| n.as_ref().to_vec()),
    })
}

fn member_change_dto(result: mdk_core::groups::UpdateGroupResult) -> MemberChangeResult {
    MemberChangeResult {
        evolution_event_json: result.evolution_event.as_json(),
        welcome_rumors: result
            .welcome_rumors
            .map(|rumors| unsigned_events_to_json(&rumors))
            .unwrap_or_default(),
    }
}

#[cfg(test)]
mod tests {
    use nostr::{EventBuilder, EventId, JsonUtil, Keys, Kind, ToBech32};

    use super::*;
    use crate::api::key_packages;
    use crate::state::{self, StorageConfig};

    fn test_db(label: &str) -> String {
        let dir = std::env::temp_dir().join("marmot_dart_tests");
        let _ = std::fs::create_dir_all(&dir);
        dir.join(format!("grp_{}_{}.db", label, std::process::id()))
            .to_string_lossy()
            .to_string()
    }

    fn init_session(db_path: &str) {
        state::initialise(
            db_path.to_string(),
            StorageConfig::SqliteWithKey {
                db_path: db_path.to_string(),
                db_key: vec![0xEFu8; 32],
            },
        )
        .expect("init session");
    }

    struct Party {
        db: String,
        keys: Keys,
        npub: String,
    }

    impl Party {
        fn new(label: &str) -> Self {
            let db = test_db(label);
            init_session(&db);
            let keys = Keys::generate();
            let npub = keys.public_key().to_bech32().unwrap();
            Self { db, keys, npub }
        }
    }

    impl Drop for Party {
        fn drop(&mut self) {
            state::remove_session(&self.db);
            let _ = std::fs::remove_file(&self.db);
        }
    }

    fn bob_key_package_event(bob: &Party) -> String {
        let data = key_packages::create(
            bob.db.clone(),
            bob.npub.clone(),
            vec!["wss://test.relay".into()],
        )
        .expect("bob kp");
        EventBuilder::new(Kind::Custom(30443), data.content)
            .tags(
                data.tags_30443
                    .iter()
                    .map(|t| nostr::Tag::parse(t.clone()).expect("tag")),
            )
            .sign_with_keys(&bob.keys)
            .expect("sign bob kp")
            .as_json()
    }

    #[test]
    fn create_group_and_welcome_flow() {
        let alice = Party::new("alice_create");
        let bob = Party::new("bob_create");

        let bob_kp_json = bob_key_package_event(&bob);
        let result = create(
            alice.db.clone(),
            alice.npub.clone(),
            CreateGroupParams {
                name: "Test".into(),
                description: "desc".into(),
                relay_urls: vec!["wss://test.relay".into()],
                member_key_package_event_jsons: vec![bob_kp_json],
            },
        )
        .expect("create group");

        assert_eq!(result.group.name, "Test");
        assert_eq!(result.group.description, "desc");
        assert_eq!(result.group.admin_npubs, vec![alice.npub.clone()]);
        assert_eq!(result.group.member_count, 2);
        assert_eq!(result.welcome_rumors.len(), 1);

        // Bob processes and accepts the welcome
        let welcome_json = &result.welcome_rumors[0];
        process_welcome(
            bob.db.clone(),
            EventId::all_zeros().to_hex(),
            welcome_json.clone(),
        )
        .expect("process welcome");

        let pending = get_pending_welcomes(bob.db.clone()).expect("pending welcomes");
        assert_eq!(pending.len(), 1);
        assert_eq!(pending[0].group_name, "Test");
        assert_eq!(pending[0].member_count, 2);

        accept_welcome(bob.db.clone(), pending[0].id.clone()).expect("accept welcome");
    }

    #[test]
    fn list_groups_and_members() {
        let alice = Party::new("alice_list");
        let bob = Party::new("bob_list");

        let bob_kp_json = bob_key_package_event(&bob);
        let created = create(
            alice.db.clone(),
            alice.npub.clone(),
            CreateGroupParams {
                name: "List Test".into(),
                description: "".into(),
                relay_urls: vec!["wss://test.relay".into()],
                member_key_package_event_jsons: vec![bob_kp_json],
            },
        )
        .expect("create");

        // Alice lists
        let groups = list(alice.db.clone()).expect("alice list");
        assert_eq!(groups.len(), 1);
        assert_eq!(groups[0].name, "List Test");
        assert_eq!(groups[0].member_count, 2);

        let members = get_members(alice.db.clone(), groups[0].id.clone())
            .expect("alice members");
        assert_eq!(members.len(), 2);

        // Bob accepts then lists
        process_welcome(
            bob.db.clone(),
            EventId::all_zeros().to_hex(),
            created.welcome_rumors[0].clone(),
        )
        .expect("bob process");
        let pending = get_pending_welcomes(bob.db.clone()).expect("pending");
        accept_welcome(bob.db.clone(), pending[0].id.clone()).expect("accept");

        let bob_groups = list(bob.db.clone()).expect("bob list");
        assert_eq!(bob_groups.len(), 1);
    }

    #[test]
    fn add_and_remove_member() {
        let alice = Party::new("alice_member");
        let bob = Party::new("bob_member");
        let carol_keys = Keys::generate();
        let carol_npub = carol_keys.public_key().to_bech32().unwrap();
        let carol_db = test_db("carol_member");
        init_session(&carol_db);

        let bob_kp_json = bob_key_package_event(&bob);
        let created = create(
            alice.db.clone(),
            alice.npub.clone(),
            CreateGroupParams {
                name: "Member Ops".into(),
                description: "".into(),
                relay_urls: vec!["wss://test.relay".into()],
                member_key_package_event_jsons: vec![bob_kp_json],
            },
        )
        .expect("create");
        let group_id = &created.group.id;

        // Bob accepts
        process_welcome(
            bob.db.clone(),
            EventId::all_zeros().to_hex(),
            created.welcome_rumors[0].clone(),
        )
        .expect("bob process");
        let pending = get_pending_welcomes(bob.db.clone()).expect("pending");
        accept_welcome(bob.db.clone(), pending[0].id.clone()).expect("accept");

        // Carol creates a key package, alice adds her
        let carol_kp = key_packages::create(
            carol_db.clone(),
            carol_npub.clone(),
            vec!["wss://test.relay".into()],
        )
        .expect("carol kp");
        let carol_signed = EventBuilder::new(Kind::Custom(30443), carol_kp.content)
            .tags(
                carol_kp
                    .tags_30443
                    .iter()
                    .map(|t| nostr::Tag::parse(t.clone()).expect("tag")),
            )
            .sign_with_keys(&carol_keys)
            .expect("sign carol")
            .as_json();

        let added = add_member(alice.db.clone(), group_id.clone(), carol_signed)
            .expect("add member");
        assert!(!added.evolution_event_json.is_empty());
        assert_eq!(added.welcome_rumors.len(), 1);

        // Carol accepts
        process_welcome(
            carol_db.clone(),
            EventId::all_zeros().to_hex(),
            added.welcome_rumors[0].clone(),
        )
        .expect("carol process");
        let carol_pending =
            get_pending_welcomes(carol_db.clone()).expect("carol pending");
        accept_welcome(carol_db.clone(), carol_pending[0].id.clone())
            .expect("carol accept");

        let members = get_members(alice.db.clone(), group_id.clone())
            .expect("members after add");
        assert_eq!(members.len(), 3);

        // Remove bob
        let removed = remove_member(alice.db.clone(), group_id.clone(), bob.npub.clone())
            .expect("remove bob");
        assert!(!removed.evolution_event_json.is_empty());

        let members_after = get_members(alice.db.clone(), group_id.clone())
            .expect("members after remove");
        assert_eq!(members_after.len(), 2);

        state::remove_session(&carol_db);
        let _ = std::fs::remove_file(&carol_db);
    }

    #[test]
    fn update_group_metadata_all_fields() {
        let alice = Party::new("alice_meta");
        let bob = Party::new("bob_meta");

        let bob_kp_json = bob_key_package_event(&bob);
        let created = create(
            alice.db.clone(),
            alice.npub.clone(),
            CreateGroupParams {
                name: "Original".into(),
                description: "old desc".into(),
                relay_urls: vec!["wss://test.relay".into()],
                member_key_package_event_jsons: vec![bob_kp_json],
            },
        )
        .expect("create");
        let group_id = &created.group.id;

        let commit = update_group_metadata(
            alice.db.clone(),
            group_id.clone(),
            GroupMetadataUpdate {
                name: Some("Updated".into()),
                description: Some("new desc".into()),
                relay_urls: Some(vec!["wss://new.relay".into()]),
                admin_npubs: Some(vec![alice.npub.clone()]),
            },
        )
        .expect("update metadata");
        assert!(!commit.is_empty());

        let groups = list(alice.db.clone()).expect("list after update");
        assert_eq!(groups[0].name, "Updated");
        assert_eq!(groups[0].description, "new desc");
    }

    #[test]
    fn group_image_prepare_set_clear_decrypt() {
        let alice = Party::new("alice_img");
        let bob = Party::new("bob_img");

        let bob_kp_json = bob_key_package_event(&bob);
        let created = create(
            alice.db.clone(),
            alice.npub.clone(),
            CreateGroupParams {
                name: "Image Test".into(),
                description: "".into(),
                relay_urls: vec!["wss://test.relay".into()],
                member_key_package_event_jsons: vec![bob_kp_json],
            },
        )
        .expect("create");
        let group_id = &created.group.id;

        // Minimal 1x1 PNG
        // Valid minimal JPEG (1x1 red pixel)
        let image_data = vec![
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
            0x01, 0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
            0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08, 0x07, 0x07, 0x07, 0x09,
            0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
            0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20,
            0x24, 0x2E, 0x27, 0x20, 0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29,
            0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27, 0x39, 0x3D, 0x38, 0x32,
            0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
            0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x1F, 0x00, 0x00,
            0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
            0x09, 0x0A, 0x0B, 0xFF, 0xC4, 0x00, 0xB5, 0x10, 0x00, 0x02, 0x01, 0x03,
            0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
            0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06,
            0x13, 0x51, 0x61, 0x07, 0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08,
            0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0, 0x24, 0x33, 0x62, 0x72,
            0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
            0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45,
            0x46, 0x47, 0x48, 0x49, 0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
            0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x73, 0x74, 0x75,
            0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
            0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3,
            0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6,
            0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5, 0xC6, 0xC7, 0xC8, 0xC9,
            0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
            0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4,
            0xF5, 0xF6, 0xF7, 0xF8, 0xF9, 0xFA, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01,
            0x00, 0x00, 0x3F, 0x00, 0x7B, 0x40, 0x00, 0xFF, 0xD9,
        ];
        let prep = prepare_group_image(image_data.clone(), "image/jpeg".into())
            .expect("prepare image");

        assert!(!prep.encrypted_data.is_empty());
        assert_eq!(prep.mime_type, "image/jpeg");
        assert!(!prep.upload_nsec.is_empty());
        assert!(!prep.upload_pubkey_hex.is_empty());

        // Set image
        let commit = set_group_image(
            alice.db.clone(),
            group_id.clone(),
            prep.image_hash.clone(),
            prep.image_key.clone(),
            prep.image_nonce.clone(),
            prep.image_upload_key.clone(),
        )
        .expect("set image");
        assert!(!commit.is_empty());

        let groups = list(alice.db.clone()).expect("list after set image");
        assert!(groups[0].image_hash.is_some());

        // Decrypt — returns the processed (EXIF-stripped) image, not the original
        let decrypted = decrypt_group_image_blob(
            prep.encrypted_data.clone(),
            prep.image_hash.clone(),
            prep.image_key.clone(),
            prep.image_nonce.clone(),
        )
        .expect("decrypt image");
        assert!(!decrypted.is_empty());

        // Clear image
        let clear_commit = clear_group_image(alice.db.clone(), group_id.clone())
            .expect("clear image");
        assert!(!clear_commit.is_empty());

        let groups_after = list(alice.db.clone()).expect("list after clear");
        assert!(groups_after[0].image_hash.is_none());
    }

    #[test]
    fn create_group_invalid_npub_returns_error() {
        let alice = Party::new("alice_bad");
        let result = create(
            alice.db.clone(),
            "not-a-npub".into(),
            CreateGroupParams {
                name: "Bad".into(),
                description: "".into(),
                relay_urls: vec![],
                member_key_package_event_jsons: vec![],
            },
        );
        assert!(result.is_err());
    }
}
