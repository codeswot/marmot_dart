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
