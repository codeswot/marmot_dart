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

- `buildUnsignedRumor({npub, content, contentType?})` — build unsigned kind-9 rumor (top-level, pure)
- `sendMessage(unsignedRumorJson, groupId)` — encrypt rumor via MLS, return kind:445 event
- `buildMediaRumor({npub, groupId, caption, url, originalHash, mimeType, filename, nonce, ...})` — build media rumor with imeta tag
- `sendStructured(npub, groupId, payload)` — convenience for JSON payloads
- `processIncoming(nostrEventJson)` — decrypt and apply incoming event
- `getMessages(groupId, {params})` — list stored messages, paginated
- `getMessage(groupId, eventIdHex)` — single message by event ID
- `getLastMessage(groupId)` — most recent message

### Media (MIP-04)

- `encryptMedia(groupId, data, mimeType, filename)` — encrypt file for group
- `decryptMedia(groupId, encryptedData, mediaRef)` — decrypt downloaded blob

### Top-level exports

- `buildUnsignedRumor` — pure function, no Marmot instance needed
- `signEvent` — pure function, sign any Nostr event
- `MarmotIdentity` — static identity helpers
- Models: `StorageConfig`, `NostrKeypair`, `KeyPackageEventData`, `CreateGroupParams`, `GroupCreateResult`, `MarmotGroup`, `MarmotMember`, `PendingWelcome`, `MemberChangeResult`, `GroupMetadataUpdate`, `GroupImagePrepared`, `MarmotMessage`, `MarmotMediaRef`, `MessageListParams`, `EncryptedMediaOutput`, `MediaRefInput`, `MarmotError`
