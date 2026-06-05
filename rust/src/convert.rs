use mdk_core::GroupId;
use nostr::{Event, JsonUtil, PublicKey, RelayUrl, Tag, ToBech32, UnsignedEvent};

use crate::api::error::MarmotError;

pub(crate) fn parse_events(jsons: &[String]) -> Result<Vec<Event>, MarmotError> {
    jsons
        .iter()
        .map(|j| Event::from_json(j).map_err(|e| MarmotError::InvalidEvent(e.to_string())))
        .collect()
}

pub(crate) fn unsigned_events_to_json(events: &[UnsignedEvent]) -> Vec<String> {
    events.iter().map(|e| e.as_json()).collect()
}

pub(crate) fn parse_relays(urls: &[String]) -> Result<Vec<RelayUrl>, MarmotError> {
    urls.iter()
        .map(|u| RelayUrl::parse(u).map_err(|_| MarmotError::InvalidRelayUrl(u.clone())))
        .collect()
}

pub(crate) fn tags_to_vecs(tags: &[Tag]) -> Vec<Vec<String>> {
    tags.iter().map(|t| t.as_slice().to_vec()).collect()
}

pub(crate) fn group_id_hex(group_id: &GroupId) -> String {
    hex::encode(group_id.as_slice())
}

pub(crate) fn group_id_from_hex(value: &str) -> Result<GroupId, MarmotError> {
    let bytes = hex::decode(value).map_err(|_| MarmotError::GroupNotFound)?;
    Ok(GroupId::from_slice(&bytes))
}

pub(crate) fn pubkey_npub(pubkey: &PublicKey) -> Result<String, MarmotError> {
    pubkey
        .to_bech32()
        .map_err(|e| MarmotError::Mdk(e.to_string()))
}

pub(crate) fn parse_pubkey(value: &str) -> Result<PublicKey, MarmotError> {
    PublicKey::parse(value).map_err(|_| MarmotError::InvalidPublicKey)
}
