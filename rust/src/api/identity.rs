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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn generate_returns_valid_keypair() {
        let kp = generate();
        assert!(kp.npub.starts_with("npub1"), "npub: {}", kp.npub);
        assert!(kp.nsec.as_ref().unwrap().starts_with("nsec1"));
        assert_eq!(kp.pubkey_hex.len(), 64);
    }

    #[test]
    fn import_from_nsec_roundtrip() {
        let kp = generate();
        let nsec = kp.nsec.clone().unwrap();
        let imported = import_from_nsec(nsec).expect("import from nsec");
        assert_eq!(imported.npub, kp.npub);
        assert_eq!(imported.pubkey_hex, kp.pubkey_hex);
    }

    #[test]
    fn validate_nsec_rejects_garbage() {
        assert!(!validate_nsec("not-a-key".into()));
        assert!(!validate_nsec("".into()));
    }

    #[test]
    fn validate_nsec_accepts_valid() {
        let kp = generate();
        assert!(validate_nsec(kp.nsec.unwrap()));
    }

    #[test]
    fn npub_from_nsec_derives_correctly() {
        let kp = generate();
        let npub = npub_from_nsec(kp.nsec.unwrap()).expect("npub from nsec");
        assert_eq!(npub, kp.npub);
    }

    #[test]
    fn npub_from_nsec_invalid_returns_error() {
        assert!(npub_from_nsec("not-a-key".into()).is_err());
    }

    #[test]
    fn pubkey_hex_from_npub_roundtrip() {
        let kp = generate();
        let hex = pubkey_hex_from_npub(kp.npub).expect("hex from npub");
        assert_eq!(hex, kp.pubkey_hex);
    }

    #[test]
    fn pubkey_hex_from_npub_invalid_returns_error() {
        assert!(pubkey_hex_from_npub("npub1bad".into()).is_err());
    }
}
