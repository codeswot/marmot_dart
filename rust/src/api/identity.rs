use nostr::{Keys, ToBech32};

use crate::api::error::MarmotError;

pub struct NostrKeypair {
    pub npub: String,
    pub nsec: Option<String>,
    pub pubkey_hex: String,
}

/// Generate a new Nostr keypair. Pure function — no MDK state needed.
pub fn generate() -> NostrKeypair {
    let keys = Keys::generate();
    keypair_with_secret(&keys).expect("bech32 encoding cannot fail for valid keys")
}

/// Parse nsec and return the full keypair. Pure function — no MDK state needed.
pub fn import_from_nsec(nsec: String) -> Result<NostrKeypair, MarmotError> {
    let keys = Keys::parse(&nsec)?;
    keypair_with_secret(&keys)
}

pub fn validate_nsec(nsec: String) -> bool {
    Keys::parse(&nsec).is_ok()
}

pub fn npub_from_nsec(nsec: String) -> Result<String, MarmotError> {
    let keys = Keys::parse(&nsec)?;
    keys.public_key()
        .to_bech32()
        .map_err(|e| MarmotError::Mdk(e.to_string()))
}

/// Convert a bech32 npub to its hex representation. Used for Nostr relay filters.
pub fn pubkey_hex_from_npub(npub: String) -> Result<String, MarmotError> {
    let pubkey = nostr::PublicKey::parse(&npub).map_err(|_| MarmotError::InvalidNsec)?;
    Ok(pubkey.to_hex())
}

fn keypair_with_secret(keys: &Keys) -> Result<NostrKeypair, MarmotError> {
    let nsec = keys
        .secret_key()
        .to_bech32()
        .map_err(|e| MarmotError::Mdk(e.to_string()))?;
    let npub = keys
        .public_key()
        .to_bech32()
        .map_err(|e| MarmotError::Mdk(e.to_string()))?;
    Ok(NostrKeypair {
        npub,
        nsec: Some(nsec),
        pubkey_hex: keys.public_key().to_hex(),
    })
}
