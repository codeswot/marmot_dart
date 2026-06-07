## 0.0.3

- `buildUnsignedRumor` now uses named parameters with optional `contentType` for structured (JSON) payloads. The receiver's `MarmotMessage.payloadJson` is populated when a content-type tag is present.
- New `Marmot.sendStructured(npub, groupId, payload)` — one-call convenience for sending JSON messages.
- New `Marmot.getMessages(groupId, {params})` — paginated retrieval of stored messages from the encrypted local DB.
- New `Marmot.getMessage(groupId, eventIdHex)` — single message lookup by Nostr event ID.
- New `Marmot.getLastMessage(groupId)` — most recent message in a group.
- New `MessageListParams` model (limit, offset, sortByProcessedAt).
- New `Marmot.leaveGroup(groupId)` — remove self from a group via MLS. Returns commit event to publish.
- New `Marmot.deleteMessagesForGroup(groupId)` — delete all locally stored messages for a group. Group stays active.
- New `Marmot.deleteGroup(groupId)` — delete all local state for a group. Idempotent, local-only.
- New `MarmotGroup` fields: `lastMessageId`, `lastMessageAtSecs`, `lastMessageProcessedAtSecs` — updated automatically on every send/receive.
- Comprehensive test suite: 22 Rust tests (identity, key packages, groups, messages, media roundtrip) and 42 Dart model tests.
- Codebase cleanup: consolidated redundant wrapper files; `buildUnsignedRumor` and `signEvent` now top-level in `marmot.dart`.

## 0.0.2

- Bumped homepage and repository URLs.

## 0.0.1

Initial development release. Built on MDK `0.8` via flutter_rust_bridge `2.12`.

### Storage

Three backends via `StorageConfig`:

- `StorageConfig.memory` — in-memory storage (ephemeral, for testing)
- `StorageConfig.sqlite(dbPath, serviceId, keyId)` — keyring-managed encryption
- `StorageConfig.sqliteWithKey(dbPath, dbKey)` — host supplies 32-byte encryption key

Call `Marmot.initKeyringStore()` once before using `.sqlite`.

### Identity (`MarmotIdentity`)

- `generate()` — new Nostr keypair (nsec returned, host must persist)
- `importFromNsec(nsec)` — import existing keypair
- `validateNsec(nsec)` — check validity
- `npubFromNsec(nsec)` — derive npub
- `pubkeyHexFromNpub(npub)` — convert bech32 to hex

Pure functions — no MDK state needed. Keys held in memory only for current session.

### Key packages

- `Marmot.createKeyPackage(npub, relayUrls)` — mint MLS key package, return pieces
- `Marmot.createSignedKeyPackage(nsec, relayUrls)` — mint + sign a kind:30443 event
- `signEvent(nsec, unsignedEventJson)` — top-level pure function

### Groups

Full MLS group lifecycle on `Marmot` instance:

- `createGroup(creatorNpub, params)` — create group, return welcome rumors
- `processWelcome(wrapperEventId, welcomeRumorJson)` — parse incoming welcome
- `getPendingWelcomes()` — list unaccepted invites
- `acceptWelcome(welcomeId)` — join a group
- `listGroups()` — all groups for this identity
- `getMembers(groupId)` — member list
- `addMember(groupId, keyPackageEventJson)` — add member, return commit + welcome
- `removeMember(groupId, npub)` — remove member, return commit
- `updateGroupMetadata(groupId, {name, description, relayUrls, adminNpubs})` — edit MIP-01 metadata
- `Marmot.prepareGroupImage(imageData, mimeType)` — encrypt group image (static)
- `setGroupImage(groupId, {imageHash, imageKey, imageNonce, imageUploadKey})` — store image refs in metadata
- `clearGroupImage(groupId)` — remove group image
- `Marmot.decryptGroupImage({encryptedData, imageHash, imageKey, imageNonce})` — decrypt downloaded blob (static)

### Messages

- `buildUnsignedRumor(npub, content)` — build unsigned kind-9 rumor (top-level, pure)
- `sendMessage(unsignedRumorJson, groupId)` — encrypt rumor via MLS, return kind:445 event
- `buildMediaRumor({...})` — build media rumor with MIP-04 imeta tag
- `processIncoming(nostrEventJson)` — decrypt and apply incoming event

### Media (MIP-04)

- `encryptMedia(groupId, data, mimeType, filename)` — encrypt file for group
- `decryptMedia(groupId, encryptedData, mediaRef)` — decrypt downloaded blob

### Top-level exports

`buildUnsignedRumor`, `signEvent`, `MarmotIdentity`, plus models: `StorageConfig`, `NostrKeypair`, `KeyPackageEventData`, `CreateGroupParams`, `GroupCreateResult`, `MarmotGroup`, `MarmotMember`, `PendingWelcome`, `MemberChangeResult`, `GroupMetadataUpdate`, `GroupImagePrepared`, `MarmotMessage`, `MarmotMediaRef`, `EncryptedMediaOutput`, `MediaRefInput`, `MarmotError`
