use crate::api::error::MarmotError;
use crate::state::{self, StorageConfig};

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn init_keyring_store() -> Result<(), MarmotError> {
    state::init_keyring_store()
}

pub fn init_mdk(db_path: String, storage: StorageConfig) -> Result<(), MarmotError> {
    state::initialise(db_path, storage)
}

pub fn remove_session(db_path: String) {
    state::remove_session(&db_path);
}
