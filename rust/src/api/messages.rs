use mdk_core::encrypted_media::EncryptedMediaUpload;
use mdk_core::messages::MessageProcessingResult;
use mdk_storage_traits::groups::{MessageSortOrder, Pagination};
use mdk_storage_traits::messages::types::Message;
use nostr::{Event, EventBuilder, JsonUtil, Kind, Tag, TagKind, UnsignedEvent};

use crate::api::error::MarmotError;
use crate::convert::{group_id_from_hex, group_id_hex, parse_pubkey, pubkey_npub};
use crate::state;

const GROUP_MESSAGE_KIND: u16 = 9;
const CONTENT_TYPE_TAG: &str = "content-type";
const IMETA_TAG: &str = "imeta";

pub struct MarmotMessage {
    pub id: String,
    pub group_id: String,
    pub sender_npub: String,
    pub text: Option<String>,
    pub content_type: Option<String>,
    pub payload_json: Option<String>,
    pub timestamp_secs: i64,    
    pub media: Vec<MarmotMediaRef>,
}


pub struct MarmotMediaRef {
    pub url: String,
    pub original_hash: Vec<u8>,
    pub mime_type: String,
    pub filename: String,
    pub scheme_version: String,
    pub nonce: Vec<u8>,
    pub dimensions_width: Option<u32>,
    pub dimensions_height: Option<u32>,
}

/// Build an unsigned kind-9 rumor. Pass [content_type] (e.g. "application/json")
/// to tag the payload — the receiver will see it in [MarmotMessage.contentType] and
/// [MarmotMessage.payloadJson] instead of [MarmotMessage.text].
pub fn build_unsigned_rumor(
    npub: String,
    content: String,
    content_type: Option<String>,
) -> Result<String, MarmotError> {
    let pubkey = parse_pubkey(&npub)?;
    let mut builder = EventBuilder::new(Kind::Custom(GROUP_MESSAGE_KIND), content);
    if let Some(ct) = content_type {
        builder = builder.tag(Tag::parse(["content-type", &ct]).map_err(|e| MarmotError::InvalidEvent(e.to_string()))?);
    }
    let rumor = builder.build(pubkey);
    Ok(rumor.as_json())
}

#[allow(clippy::too_many_arguments)]
pub fn build_media_rumor(
    db_path: String,
    npub: String,
    group_id: String,
    caption: String,
    url: String,
    original_hash: Vec<u8>,
    mime_type: String,
    filename: String,
    nonce: Vec<u8>,
    blurhash: Option<String>,
    thumbhash: Option<String>,
    dimensions_width: Option<u32>,
    dimensions_height: Option<u32>,
) -> Result<String, MarmotError> {
    let pubkey = parse_pubkey(&npub)?;
    let original_hash: [u8; 32] = original_hash
        .as_slice()
        .try_into()
        .map_err(|_| MarmotError::Media("invalid original_hash length".to_string()))?;
    let nonce: [u8; 12] = nonce
        .as_slice()
        .try_into()
        .map_err(|_| MarmotError::Media("invalid nonce length".to_string()))?;
    let dimensions = match (dimensions_width, dimensions_height) {
        (Some(w), Some(h)) => Some((w, h)),
        _ => None,
    };

    let upload = EncryptedMediaUpload {
        encrypted_data: Vec::new(),
        original_hash,
        encrypted_hash: [0u8; 32],
        mime_type,
        filename,
        original_size: 0,
        encrypted_size: 0,
        dimensions,
        blurhash,
        thumbhash,
        nonce,
    };

    state::with_state(&db_path, |s| {
        let gid = group_id_from_hex(&group_id)?;
        let manager = s.mdk.media_manager(gid);
        let imeta = manager.create_imeta_tag(&upload, &url);
        let rumor = EventBuilder::new(Kind::Custom(GROUP_MESSAGE_KIND), caption)
            .tag(imeta)
            .build(pubkey);
        Ok(rumor.as_json())
    })
}

pub fn send(
    db_path: String,
    unsigned_rumor_json: String,
    group_id: String,
) -> Result<String, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    let rumor = UnsignedEvent::from_json(&unsigned_rumor_json)
        .map_err(|e| MarmotError::InvalidEvent(e.to_string()))?;
    state::with_state(&db_path, |s| {
        let event = s.mdk.create_message(&gid, rumor, None)?;
        Ok(event.as_json())
    })
}

pub fn process_incoming(
    db_path: String,
    nostr_event_json: String,
) -> Result<Option<MarmotMessage>, MarmotError> {
    let event = Event::from_json(&nostr_event_json)
        .map_err(|e| MarmotError::InvalidEvent(e.to_string()))?;
    state::with_state(&db_path, |s| match s.mdk.process_message(&event)? {
        MessageProcessingResult::ApplicationMessage(message) => {
            let manager = s.mdk.media_manager(message.mls_group_id.clone());
            let media = message
                .tags
                .iter()
                .filter(|t| t.kind() == TagKind::Custom(IMETA_TAG.into()))
                .filter_map(|t| manager.parse_imeta_tag(t).ok())
                .map(|r| MarmotMediaRef {
                    url: r.url,
                    original_hash: r.original_hash.to_vec(),
                    mime_type: r.mime_type,
                    filename: r.filename,
                    scheme_version: r.scheme_version,
                    nonce: r.nonce.to_vec(),
                    dimensions_width: r.dimensions.map(|d| d.0),
                    dimensions_height: r.dimensions.map(|d| d.1),
                })
                .collect();
            Ok(Some(message_dto(&message, media)?))
        }
        _ => Ok(None),
    })
}

pub struct MessageListParams {
    pub limit: Option<u32>,
    pub offset: Option<u32>,
    pub sort_by_processed_at: Option<bool>,
}

/// List messages for a group, newest first. Paginate with [MessageListParams].
pub fn get_messages(
    db_path: String,
    group_id: String,
    params: Option<MessageListParams>,
) -> Result<Vec<MarmotMessage>, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    state::with_state(&db_path, |s| {
        let pagination = params
            .map(|p| {
                let sort_order = if p.sort_by_processed_at.unwrap_or(false) {
                    MessageSortOrder::ProcessedAtFirst
                } else {
                    MessageSortOrder::CreatedAtFirst
                };
                Pagination::with_sort_order(
                    p.limit.map(|l| l as usize),
                    p.offset.map(|o| o as usize),
                    sort_order,
                )
            })
            .unwrap_or_default();
        let messages = s.mdk.get_messages(&gid, Some(pagination))?;
        messages
            .iter()
            .map(|m| {
                let manager = s.mdk.media_manager(m.mls_group_id.clone());
                let media: Vec<MarmotMediaRef> = m
                    .tags
                    .iter()
                    .filter(|t| t.kind() == TagKind::Custom(IMETA_TAG.into()))
                    .filter_map(|t| manager.parse_imeta_tag(t).ok())
                    .map(|r| MarmotMediaRef {
                        url: r.url,
                        original_hash: r.original_hash.to_vec(),
                        mime_type: r.mime_type,
                        filename: r.filename,
                        scheme_version: r.scheme_version,
                        nonce: r.nonce.to_vec(),
                        dimensions_width: r.dimensions.map(|d| d.0),
                        dimensions_height: r.dimensions.map(|d| d.1),
                    })
                    .collect();
                message_dto(m, media)
            })
            .collect()
    })
}

/// Look up a single stored message by Nostr event ID hex.
pub fn get_message(
    db_path: String,
    group_id: String,
    event_id_hex: String,
) -> Result<Option<MarmotMessage>, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    let event_id = nostr::EventId::from_hex(&event_id_hex)
        .map_err(|e| MarmotError::InvalidEvent(e.to_string()))?;
    state::with_state(&db_path, |s| {
        match s.mdk.get_message(&gid, &event_id)? {
            Some(m) => {
                let manager = s.mdk.media_manager(m.mls_group_id.clone());
                let media: Vec<MarmotMediaRef> = m
                    .tags
                    .iter()
                    .filter(|t| t.kind() == TagKind::Custom(IMETA_TAG.into()))
                    .filter_map(|t| manager.parse_imeta_tag(t).ok())
                    .map(|r| MarmotMediaRef {
                        url: r.url,
                        original_hash: r.original_hash.to_vec(),
                        mime_type: r.mime_type,
                        filename: r.filename,
                        scheme_version: r.scheme_version,
                        nonce: r.nonce.to_vec(),
                        dimensions_width: r.dimensions.map(|d| d.0),
                        dimensions_height: r.dimensions.map(|d| d.1),
                    })
                    .collect();
                Ok(Some(message_dto(&m, media)?))
            }
            None => Ok(None),
        }
    })
}

/// Return the most recent message in a group, or None if empty.
pub fn get_last_message(
    db_path: String,
    group_id: String,
) -> Result<Option<MarmotMessage>, MarmotError> {
    let gid = group_id_from_hex(&group_id)?;
    state::with_state(&db_path, |s| {
        match s.mdk.get_last_message(&gid, MessageSortOrder::CreatedAtFirst)? {
            Some(m) => {
                let manager = s.mdk.media_manager(m.mls_group_id.clone());
                let media: Vec<MarmotMediaRef> = m
                    .tags
                    .iter()
                    .filter(|t| t.kind() == TagKind::Custom(IMETA_TAG.into()))
                    .filter_map(|t| manager.parse_imeta_tag(t).ok())
                    .map(|r| MarmotMediaRef {
                        url: r.url,
                        original_hash: r.original_hash.to_vec(),
                        mime_type: r.mime_type,
                        filename: r.filename,
                        scheme_version: r.scheme_version,
                        nonce: r.nonce.to_vec(),
                        dimensions_width: r.dimensions.map(|d| d.0),
                        dimensions_height: r.dimensions.map(|d| d.1),
                    })
                    .collect();
                Ok(Some(message_dto(&m, media)?))
            }
            None => Ok(None),
        }
    })
}

pub(crate) fn message_dto(
    message: &Message,
    media: Vec<MarmotMediaRef>,
) -> Result<MarmotMessage, MarmotError> {
    let mut content_type: Option<String> = None;
    for tag in message.tags.iter() {
        let parts = tag.as_slice();
        if parts.first().map(String::as_str) == Some(CONTENT_TYPE_TAG) {
            content_type = parts.get(1).cloned();
            break;
        }
    }

    let (text, payload_json) = match &content_type {
        Some(_) => (None, Some(message.content.clone())),
        None => (Some(message.content.clone()), None),
    };

    Ok(MarmotMessage {
        id: message.id.to_hex(),
        group_id: group_id_hex(&message.mls_group_id),
        sender_npub: pubkey_npub(&message.pubkey)?,
        text,
        content_type,
        payload_json,
        timestamp_secs: message.created_at.as_secs() as i64,
        media,
    })
}

#[cfg(test)]
mod tests {
    use mdk_core::groups::NostrGroupConfigData;
    use mdk_core::MDK;
    use mdk_memory_storage::MdkMemoryStorage;
    use nostr::{EventBuilder, EventId, Keys, Kind, RelayUrl, ToBech32};

    use super::*;
    use crate::api::groups::{self, group_dto, CreateGroupParams};
    use crate::api::key_packages;
    use crate::api::media;
    use crate::state::{self, StorageConfig};

    #[test]
    fn two_party_group_and_message() {
        let alice_keys = Keys::generate();
        let bob_keys = Keys::generate();
        let alice = test_mdk();
        let bob = test_mdk();

        let bob_kp = bob
            .create_key_package_for_event(
                &bob_keys.public_key(),
                vec![RelayUrl::parse("wss://test.relay").unwrap()],
            )
            .expect("key package");
        let bob_key_package_event =
            EventBuilder::new(Kind::Custom(30443), bob_kp.content)
                .tags(bob_kp.tags_30443)
                .sign_with_keys(&bob_keys)
                .expect("sign");

        let config = NostrGroupConfigData::new(
            "Test Group".to_string(),
            "A group".to_string(),
            None,
            None,
            None,
            vec![RelayUrl::parse("wss://test.relay").unwrap()],
            vec![alice_keys.public_key()],
        );
        let created = alice
            .create_group(&alice_keys.public_key(), vec![bob_key_package_event], config)
            .expect("create group");
        let group_id = created.group.mls_group_id.clone();
        alice.merge_pending_commit(&group_id).expect("merge");

        let group = group_dto(&alice, &created.group).expect("group dto");
        assert_eq!(group.name, "Test Group");
        assert_eq!(group.member_count, 2);

        let welcome_rumor = &created.welcome_rumors[0];
        let welcome = bob
            .process_welcome(&EventId::all_zeros(), welcome_rumor)
            .expect("process welcome");
        bob.accept_welcome(&welcome).expect("accept welcome");

        let rumor =
            EventBuilder::new(Kind::Custom(GROUP_MESSAGE_KIND), "hello bob")
                .build(alice_keys.public_key());
        let event = alice
            .create_message(&group_id, rumor, None)
            .expect("create message");

        match bob.process_message(&event).expect("process message") {
            MessageProcessingResult::ApplicationMessage(message) => {
                let dto = message_dto(&message, Vec::new()).expect("message dto");
                assert_eq!(dto.text.as_deref(), Some("hello bob"));
                assert_eq!(
                    dto.sender_npub,
                    alice_keys.public_key().to_bech32().unwrap()
                );
            }
            other => panic!("expected application message, got {other:?}"),
        }
    }

    fn test_mdk() -> MDK<MdkMemoryStorage> {
        MDK::new(MdkMemoryStorage::default())
    }

    // ── media + imeta roundtrip through the exact binding-call path ──────────

    #[cfg(feature = "mip04")]
    #[test]
    fn media_encrypt_imeta_roundtrip() {
        let alice_keys = Keys::generate();
        let bob_keys = Keys::generate();
        let alice_npub = alice_keys.public_key().to_bech32().unwrap();
        let bob_npub = bob_keys.public_key().to_bech32().unwrap();

        // Temp DBs — each party gets their own
        let alice_db = temp_db_path("alice");
        let bob_db = temp_db_path("bob");

        state::initialise(
            alice_db.clone(),
            StorageConfig::SqliteWithKey {
                db_path: alice_db.clone(),
                db_key: fixed_32b(),
            },
        )
        .expect("alice init");
        state::initialise(
            bob_db.clone(),
            StorageConfig::SqliteWithKey {
                db_path: bob_db.clone(),
                db_key: fixed_32b(),
            },
        )
        .expect("bob init");

        // Bob mints a key package, then signs the event himself
        let bob_kp = key_packages::create(
            bob_db.clone(),
            bob_npub.clone(),
            vec!["wss://test.relay".into()],
        )
        .expect("bob key package");
        let bob_signed_kp = nostr::EventBuilder::new(
            nostr::Kind::Custom(30443),
            bob_kp.content,
        )
        .tags(
            bob_kp
                .tags_30443
                .iter()
                .map(|t| nostr::Tag::parse(t.clone()).expect("tag parse")),
        )
        .sign_with_keys(&bob_keys)
        .expect("sign bob kp")
        .as_json();

        // Alice creates the group
        let created = groups::create(
            alice_db.clone(),
            alice_npub.clone(),
            CreateGroupParams {
                name: "Media Test".into(),
                description: "Media roundtrip".into(),
                relay_urls: vec!["wss://test.relay".into()],
                member_key_package_event_jsons: vec![bob_signed_kp],
            },
        )
        .expect("create group");
        let group_id = &created.group.id;

        // Bob accepts the welcome
        let welcome_rumor = &created.welcome_rumors[0];
        groups::process_welcome(
            bob_db.clone(),
            EventId::all_zeros().to_hex(),
            welcome_rumor.clone(),
        )
        .expect("bob process welcome");
        let pending = groups::get_pending_welcomes(bob_db.clone()).expect("pending");
        groups::accept_welcome(bob_db.clone(), pending[0].id.clone()).expect("accept welcome");

        // ── Alice: encrypt media → build imeta rumor → send ──────────────────

        let plaintext = b"hello secret media data!".to_vec();
        let enc = media::encrypt_media(
            alice_db.clone(),
            group_id.clone(),
            plaintext.clone(),
            "text/plain".into(),
            "secret.txt".into(),
        )
        .expect("encrypt media");

        let rumor = build_media_rumor(
            alice_db.clone(),
            alice_npub.clone(),
            group_id.clone(),
            "check this file".into(),
            "https://blossom.example/file".into(),
            enc.original_hash.clone(),
            enc.mime_type.clone(),
            enc.filename.clone(),
            enc.nonce.clone(),
            enc.blurhash.clone(),
            enc.thumbhash.clone(),
            enc.dimensions_width,
            enc.dimensions_height,
        )
        .expect("build media rumor");

        let event_json = send(alice_db.clone(), rumor, group_id.clone()).expect("send");

        // ── Bob: process incoming → verify media refs → decrypt ──────────────

        let msg = process_incoming(bob_db.clone(), event_json)
            .expect("process incoming")
            .expect("application message");

        assert_eq!(msg.text.as_deref(), Some("check this file"));
        assert_eq!(msg.sender_npub, alice_npub);
        assert_eq!(msg.media.len(), 1);

        let ref0 = &msg.media[0];
        assert_eq!(ref0.url, "https://blossom.example/file");
        assert_eq!(ref0.mime_type, "text/plain");
        assert_eq!(ref0.filename, "secret.txt");
        assert_eq!(ref0.original_hash, enc.original_hash);
        assert_eq!(ref0.nonce, enc.nonce);

        let decrypted = media::decrypt_media(
            bob_db.clone(),
            group_id.clone(),
            enc.encrypted_data.clone(),
            media::MediaRefInput {
                url: ref0.url.clone(),
                original_hash: ref0.original_hash.clone(),
                mime_type: ref0.mime_type.clone(),
                filename: ref0.filename.clone(),
                scheme_version: ref0.scheme_version.clone(),
                nonce: ref0.nonce.clone(),
            },
        )
        .expect("decrypt media");

        assert_eq!(decrypted, plaintext);

        // Cleanup
        state::remove_session(&alice_db);
        state::remove_session(&bob_db);
        let _ = std::fs::remove_file(&alice_db);
        let _ = std::fs::remove_file(&bob_db);
    }

    fn temp_db_path(label: &str) -> String {
        let dir = std::env::temp_dir().join("marmot_dart_tests");
        let _ = std::fs::create_dir_all(&dir);
        dir.join(format!("{label}_{}.db", std::process::id()))
            .to_string_lossy()
            .to_string()
    }

    fn fixed_32b() -> Vec<u8> {
        vec![0xABu8; 32]
    }
}
