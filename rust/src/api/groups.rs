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
