use thiserror::Error;

#[derive(Debug, Error)]
pub enum MarmotError {
    #[error("MDK not initialised — call Marmot.init() first")]
    NotInitialised,

    #[error("No identity — call MarmotIdentity.generate() or importNsec() first")]
    NoIdentity,

    #[error("Invalid nsec")]
    InvalidNsec,

    #[error("Invalid public key")]
    InvalidPublicKey,

    #[error("Invalid relay url: {0}")]
    InvalidRelayUrl(String),

    #[error("Invalid event json: {0}")]
    InvalidEvent(String),

    #[error("Group not found")]
    GroupNotFound,

    #[error("Welcome not found")]
    WelcomeNotFound,

    #[error("Only admins can perform this operation")]
    NotAdmin,

    #[error("Secure storage unavailable: {0}")]
    Keyring(String),

    #[error("Not supported on this platform: {0}")]
    Unsupported(String),

    #[error("Internal lock poisoned")]
    Lock,

    #[error("Media error: {0}")]
    Media(String),

    #[error("MDK error: {0}")]
    Mdk(String),
}

impl From<mdk_core::Error> for MarmotError {
    fn from(err: mdk_core::Error) -> Self {
        match err {
            mdk_core::Error::GroupNotFound => MarmotError::GroupNotFound,
            mdk_core::Error::NotAdmin => MarmotError::NotAdmin,
            mdk_core::Error::Storage(e) => MarmotError::Mdk(e.to_string()),
            other => MarmotError::Mdk(other.to_string()),
        }
    }
}

impl From<nostr::key::Error> for MarmotError {
    fn from(_: nostr::key::Error) -> Self {
        MarmotError::InvalidNsec
    }
}
