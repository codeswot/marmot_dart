use nostr::{EventBuilder, JsonUtil, Keys, Kind};

use crate::api::error::MarmotError;
use crate::convert::{parse_pubkey, parse_relays, tags_to_vecs};
use crate::state;

const KEY_PACKAGE_KIND: u16 = 30443;

pub struct KeyPackageEventData {
    pub content: String,
    pub tags_30443: Vec<Vec<String>>,
    pub tags_443: Vec<Vec<String>>,
    pub d_tag: String,
    pub hash_ref: Vec<u8>,
}

pub fn create(
    db_path: String,
    npub: String,
    relay_urls: Vec<String>,
) -> Result<KeyPackageEventData, MarmotError> {
    let pubkey = parse_pubkey(&npub)?;
    let relays = parse_relays(&relay_urls)?;
    state::with_state(&db_path, |s| {
        let data = s.mdk.create_key_package_for_event(&pubkey, relays)?;
        Ok(KeyPackageEventData {
            content: data.content,
            tags_30443: tags_to_vecs(&data.tags_30443),
            tags_443: tags_to_vecs(&data.tags_443),
            d_tag: data.d_tag,
            hash_ref: data.hash_ref,
        })
    })
}

pub fn create_signed_event(
    db_path: String,
    nsec: String,
    relay_urls: Vec<String>,
) -> Result<String, MarmotError> {
    let keys = Keys::parse(&nsec)?;
    let pubkey = keys.public_key();
    let relays = parse_relays(&relay_urls)?;
    state::with_state(&db_path, |s| {
        let data = s.mdk.create_key_package_for_event(&pubkey, relays)?;
        let event = EventBuilder::new(Kind::Custom(KEY_PACKAGE_KIND), data.content)
            .tags(data.tags_30443)
            .sign_with_keys(&keys)
            .map_err(|e| MarmotError::InvalidEvent(e.to_string()))?;
        Ok(event.as_json())
    })
}

pub fn sign_event(nsec: String, unsigned_event_json: String) -> Result<String, MarmotError> {
    let keys = Keys::parse(&nsec)?;
    let unsigned = nostr::UnsignedEvent::from_json(&unsigned_event_json)
        .map_err(|e| MarmotError::InvalidEvent(e.to_string()))?;
    let event = unsigned
        .sign_with_keys(&keys)
        .map_err(|e| MarmotError::InvalidEvent(e.to_string()))?;
    Ok(event.as_json())
}

#[cfg(test)]
mod tests {
    use nostr::{EventBuilder, JsonUtil, Keys, Kind, ToBech32};

    use super::*;
    use crate::state::{self, StorageConfig};

    fn init_test_session(label: &str) -> String {
        let dir = std::env::temp_dir().join("marmot_dart_tests");
        let _ = std::fs::create_dir_all(&dir);
        let db_path = dir
            .join(format!("kp_{}_{}.db", label, std::process::id()))
            .to_string_lossy()
            .to_string();
        state::initialise(
            db_path.clone(),
            StorageConfig::SqliteWithKey {
                db_path: db_path.clone(),
                db_key: vec![0xCDu8; 32],
            },
        )
        .expect("init");
        db_path
    }

    #[test]
    fn create_key_package_returns_all_fields() {
        let db = init_test_session("create");
        let keys = Keys::generate();
        let npub = keys.public_key().to_bech32().unwrap();

        let kp = create(db.clone(), npub, vec!["wss://relay.test".into()])
            .expect("create key package");

        assert!(!kp.content.is_empty());
        assert!(!kp.tags_30443.is_empty(), "tags_30443 must not be empty");
        assert!(!kp.d_tag.is_empty());
        assert!(!kp.hash_ref.is_empty());

        state::remove_session(&db);
        let _ = std::fs::remove_file(&db);
    }

    #[test]
    fn create_signed_event_produces_valid_json() {
        let db = init_test_session("signed");
        let keys = Keys::generate();
        let nsec = keys.secret_key().to_bech32().unwrap();

        let json =
            create_signed_event(db.clone(), nsec, vec!["wss://relay.test".into()])
                .expect("create signed event");

        let event = nostr::Event::from_json(&json).expect("parse signed event");
        assert_eq!(event.kind, Kind::Custom(KEY_PACKAGE_KIND));
        assert_eq!(event.pubkey, keys.public_key());

        state::remove_session(&db);
        let _ = std::fs::remove_file(&db);
    }

    #[test]
    fn sign_event_roundtrip() {
        let keys = Keys::generate();
        let nsec = keys.secret_key().to_bech32().unwrap();
        let unsigned = EventBuilder::new(Kind::TextNote, "hello")
            .build(keys.public_key());

        let signed_json =
            sign_event(nsec, unsigned.as_json()).expect("sign event");
        let signed = nostr::Event::from_json(&signed_json).expect("parse signed");

        assert_eq!(signed.kind, Kind::TextNote);
        assert_eq!(signed.content, "hello");
        assert_eq!(signed.pubkey, keys.public_key());
    }

    #[test]
    fn sign_event_invalid_nsec_returns_error() {
        assert!(sign_event("bad-nsec".into(), "{}".into()).is_err());
    }

    #[test]
    fn sign_event_garbage_json_returns_error() {
        let nsec = Keys::generate().secret_key().to_bech32().unwrap();
        assert!(sign_event(nsec, "not json".into()).is_err());
    }

    #[test]
    fn create_key_package_invalid_npub_returns_error() {
        let db = init_test_session("bad_npub");
        let result = create(db.clone(), "not-a-npub".into(), vec![]);
        assert!(result.is_err());

        state::remove_session(&db);
        let _ = std::fs::remove_file(&db);
    }
}
