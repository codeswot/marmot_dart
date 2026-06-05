use std::collections::HashMap;
use std::sync::Mutex;

use mdk_core::MDK;
use mdk_sqlite_storage::{EncryptionConfig, MdkSqliteStorage};

use crate::api::error::MarmotError;

pub(crate) struct AppState {
    pub mdk: MDK<MdkSqliteStorage>,
}

static SESSIONS: Mutex<Option<HashMap<String, AppState>>> = Mutex::new(None);

pub(crate) fn initialise(db_path: String, storage: StorageConfig) -> Result<(), MarmotError> {
    let mut guard = SESSIONS.lock().map_err(|_| MarmotError::Lock)?;
    let map = guard.get_or_insert_with(HashMap::new);
    if map.contains_key(&db_path) {
        return Ok(());
    }

    let sqlite_storage = match storage {
        StorageConfig::Memory => {
            return Err(MarmotError::Unsupported(
                "Memory storage requires the `test-utils` feature".to_string(),
            ));
        }
        StorageConfig::Sqlite {
            db_path,
            service_id,
            key_id,
        } => MdkSqliteStorage::new(&db_path, &service_id, &key_id)
            .map_err(|e| MarmotError::Mdk(e.to_string()))?,
        StorageConfig::SqliteWithKey { db_path, db_key } => {
            let key: [u8; 32] = db_key
                .as_slice()
                .try_into()
                .map_err(|_| {
                    MarmotError::Media("db_key must be exactly 32 bytes".to_string())
                })?;
            MdkSqliteStorage::new_with_key(&db_path, EncryptionConfig::new(key))
                .map_err(|e| MarmotError::Mdk(e.to_string()))?
        }
    };

    map.insert(db_path, AppState {
        mdk: MDK::new(sqlite_storage),
    });
    Ok(())
}

pub(crate) fn with_state<T>(
    db_path: &str,
    f: impl FnOnce(&mut AppState) -> Result<T, MarmotError>,
) -> Result<T, MarmotError> {
    let mut guard = SESSIONS.lock().map_err(|_| MarmotError::Lock)?;
    let map = guard.as_mut().ok_or(MarmotError::NotInitialised)?;
    let state = map.get_mut(db_path).ok_or(MarmotError::NotInitialised)?;
    f(state)
}

pub(crate) fn remove_session(db_path: &str) {
    if let Ok(mut guard) = SESSIONS.lock() {
        if let Some(map) = guard.as_mut() {
            map.remove(db_path);
        }
    }
}

/// Initializes the platform keyring store for automatic SQLite encryption.
/// Call once at app startup before `init` with `StorageConfig::Sqlite`.
pub fn init_keyring_store() -> Result<(), MarmotError> {
    use std::sync::OnceLock;
    static DONE: OnceLock<()> = OnceLock::new();
    if DONE.get().is_some() {
        return Ok(());
    }

    #[cfg(target_os = "macos")]
    {
        let store = apple_native_keyring_store::keychain::Store::new()
            .map_err(|e| MarmotError::Keyring(e.to_string()))?;
        keyring_core::set_default_store(store);
    }
    #[cfg(target_os = "ios")]
    {
        let store = apple_native_keyring_store::protected::Store::new()
            .map_err(|e| MarmotError::Keyring(e.to_string()))?;
        keyring_core::set_default_store(store);
    }
    #[cfg(target_os = "windows")]
    {
        let store = windows_native_keyring_store::Store::new()
            .map_err(|e| MarmotError::Keyring(e.to_string()))?;
        keyring_core::set_default_store(store);
    }
    #[cfg(target_os = "linux")]
    {
        let store = linux_keyutils_keyring_store::Store::new()
            .map_err(|e| MarmotError::Keyring(e.to_string()))?;
        keyring_core::set_default_store(store);
    }
    #[cfg(target_os = "android")]
    {
        let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            android_native_keyring_store::Store::new()
        }));
        match result {
            Ok(Ok(store)) => keyring_core::set_default_store(store),
            Ok(Err(e)) => return Err(MarmotError::Keyring(e.to_string())),
            Err(_) => {
                return Err(MarmotError::Unsupported(
                    "Android NDK context not initialized.".to_string(),
                ))
            }
        }
    }
    #[cfg(not(any(
        target_os = "macos",
        target_os = "ios",
        target_os = "windows",
        target_os = "linux",
        target_os = "android"
    )))]
    {
        return Err(MarmotError::Unsupported(
            "keyring store is not available on this platform".to_string(),
        ));
    }

    let _ = DONE.set(());
    Ok(())
}

/// Storage backend configuration — mirrors MDK's three official setup modes.
pub enum StorageConfig {
    /// In-memory storage (testing / ephemeral). Requires `test-utils` feature.
    Memory,
    /// Automatic SQLite storage. Host must call `initKeyringStore()` first.
    Sqlite {
        db_path: String,
        service_id: String,
        key_id: String,
    },
    /// Manual SQLite storage. Host supplies a 32-byte encryption key directly.
    SqliteWithKey {
        db_path: String,
        db_key: Vec<u8>,
    },
}
