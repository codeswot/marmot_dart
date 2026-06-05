## 0.0.1

Initial development release. Built on MDK `0.8` via flutter_rust_bridge `2.12`.

### Architecture: Host-App-Managed Secrets (Whitenoise Pattern)

The host Flutter app owns all secret storage. marmot_dart is a thin MDK wrapper.

- **DB encryption key**: host supplies a 32-byte key via `StorageConfig.sqliteWithKey`.
  Or use `StorageConfig.sqlite` for automatic keyring-managed keys (requires calling
  `Marmot.initKeyringStore()` first).
- **nsec**: host persists via `flutter_secure_storage` or equivalent. marmot_dart
  only holds keys in-memory for the current session via `MarmotIdentity.importNsec`.

### Three Storage Backends (`StorageConfig` enum)

- `StorageConfig.memory` — in-memory storage (testing, requires `test-utils` feature)
- `StorageConfig.sqlite(dbPath, serviceId, keyId)` — automatic keyring-managed encryption
- `StorageConfig.sqliteWithKey(dbPath, dbKey)` — host supplies 32-byte encryption key

### API

- **Init** — `Marmot.init(npub:, storage:)` with npub + storage config.
  `Marmot.initKeyringStore()` for auto keyring mode.
  `Marmot.hasIdentity()`.
- **Identity** — `MarmotIdentity.generate`, `importNsec`, `validateNsec`, `current`,
  `npubFromNsec`. In-memory only, host persists nsec.
  `MarmotIdentity.clear()` clears in-memory keys.
- **Key packages** — `MarmotKeyPackages.create` returns content + tags to publish.
- **Groups** — `MarmotGroups.create`, `processWelcome`, `getPendingWelcomes`,
  `acceptWelcome`, `list`, `getMembers`, `addMember`, `removeMember`.
- **Messages** — `MarmotMessages.send`, `sendStructured`, `processIncoming`.
- **Media (MIP-04)** — `MarmotMedia.encrypt` / `decrypt`. Enabled by default.
