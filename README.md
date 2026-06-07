# marmot_dart

End-to-end encrypted group messaging for Flutter, built on the [Marmot protocol](https://github.com/parres-hq/marmot) (MLS over Nostr) via [MDK](https://github.com/parres-hq/mdk).

`marmot_dart` is an **app-agnostic Flutter FFI plugin** — it handles identity, MLS crypto, group lifecycle, message encryption, and media encryption. You own transport (Nostr relay WebSocket connections, Blossom uploads/downloads) and UI.

> **Status:** early development, built on MDK `0.8`. Identity, key packages, groups, messages, and MIP-04 media are implemented.

## Install

```sh
flutter pub add marmot_dart
```

This is an FFI plugin — it compiles and links the MDK Rust crate via `flutter_rust_bridge` and `cargokit`.

## Usage

### Init

Three factory constructors — one call creates an initialised `Marmot` instance bound to a single encrypted database.

```dart
import 'package:marmot_dart/marmot_dart.dart';

// Host-supplied 32-byte encryption key
final marmot = await Marmot.sqliteWithKey(
  dbPath: '/path/to/marmot.db',
  dbKey: Uint8List.fromList(List.generate(32, (_) => 0x42)),
);
```

| Constructor | Backend |
| ----------- | ------- |
| `Marmot.memory(dbPath:)` | In-memory — ephemeral, for testing |
| `Marmot.sqlite(dbPath:, serviceId:, keyId:)` | Keyring-managed encryption |
| `Marmot.sqliteWithKey(dbPath:, dbKey:)` | You supply a 32-byte encryption key |

```dart
// Keyring-managed (macOS/iOS Keychain, Android Keystore, etc.)
await Marmot.initKeyringStore();
final marmot = await Marmot.sqlite(
  dbPath: '/path/to/marmot.db',
  serviceId: 'com.myapp',
  keyId: 'marmot-db-key',
);
```

### Identity

```dart
// Generate a fresh keypair
final keypair = await MarmotIdentity.generate();
// keypair.npub   — npub1...
// keypair.nsec   — nsec1... (only returned here — persist it yourself)
// keypair.pubkeyHex — hex pubkey

// Import an existing keypair from nsec
final imported = await MarmotIdentity.importFromNsec('nsec1...');

// Validate an nsec string
final valid = await MarmotIdentity.validateNsec('nsec1...');

// Derive npub from nsec
final npub = await MarmotIdentity.npubFromNsec('nsec1...');

// Convert npub to hex pubkey (useful for relay filters)
final hex = await MarmotIdentity.pubkeyHexFromNpub('npub1...');
```

`nsec` is returned only from `generate()` and `importFromNsec()`. Your app persists it (e.g. via `flutter_secure_storage`). `marmot_dart` holds keys in memory only for the current session.

### Key packages

Publish a key package so others can invite you to groups. Two paths:

**Path 1 — Signed (simplest):** pass your `nsec`, get back a signed kind:30443 event ready to publish.

```dart
final signedJson = await marmot.createSignedKeyPackage(
  nsec,
  ['wss://relay.example.com'],
);
// signedJson is a signed Nostr event — publish it to your relay
```

**Path 2 — Unsigned:** mints the MLS key package, returns the pieces. You assemble, sign, and publish the Nostr event yourself (useful when the signer is external).

```dart
final kp = await marmot.createKeyPackage(npub, ['wss://relay.example.com']);
// kp.content     — base64-encoded MLS key package
// kp.tags30443   — modern kind:30443 tags
// kp.tags443     — legacy kind:443 tags
// kp.dTag        — reuse this value when rotating
// kp.hashRef     — content hash reference

// Build the kind:30443 event with these pieces, then sign:
final signed = await signEvent(nsec, unsignedEventJson);
```

### Groups

**Sending an invite.** `createGroup` returns the group plus one welcome rumor per member. Gift-wrap (NIP-59) each rumor and publish over nostr.

```dart
final result = await marmot.createGroup(creatorNpub, CreateGroupParams(
  name: 'My Group',
  description: 'A private group',
  relayUrls: ['wss://relay.example.com'],
  memberKeyPackageEventJsons: keyPackageEvents,
));
// result.group         — MarmotGroup (id, name, adminNpubs, memberCount, ...)
// result.welcomeRumors — List<String>, one per invited member
```

**Accepting an invite.** Three steps: unwrap the gift-wrap to get the welcome rumor, process it, then accept.

```dart
// 1. Parse the welcome rumor — validates and stores it as pending
await marmot.processWelcome(wrapperEventId, welcomeRumorJson);

// 2. Inspect pending welcomes (e.g. show group name before joining)
final pending = await marmot.getPendingWelcomes();

// 3. Accept and join the group
await marmot.acceptWelcome(pending.first.id);
```

**Managing groups.**

```dart
final groups  = await marmot.listGroups();
final members = await marmot.getMembers(group.id);

// addMember / removeMember return evolution event + new welcome rumors
final change = await marmot.addMember(group.id, keyPackageEventJson);
await marmot.removeMember(group.id, npub);
```

**Editing group metadata.** Name, description, relays, and admins live in the MLS group's Marmot data extension (MIP-01). Updating any of them produces a kind:445 commit event — publish it to the group's relays. Other members apply the change when they `processIncoming` that event. Pass only the fields you want to change.

```dart
final commitJson = await marmot.updateGroupMetadata(
  group.id,
  name: 'New name',
  description: 'New description',
  // relayUrls: [...],   // optional
  // adminNpubs: [...],  // optional
);
// Publish commitJson to the group's relays
```

**Group image.** The image is encrypted (like MIP-04 media), uploaded to Blossom under a one-time derived keypair, and its hash/key/nonce stored in group metadata.

```dart
// 1. Encrypt the image
final prep = await Marmot.prepareGroupImage(imageBytes, 'image/png');

// 2. Upload prep.encryptedData to Blossom, authenticating with prep.uploadNsec
await uploadToBlossom(nsec: prep.uploadNsec, data: prep.encryptedData);

// 3. Store the image in group metadata → kind:445 commit to publish
final commitJson = await marmot.setGroupImage(
  group.id,
  imageHash: prep.imageHash,
  imageKey: prep.imageKey,
  imageNonce: prep.imageNonce,
  imageUploadKey: prep.imageUploadKey,
);

// Remove it later:
await marmot.clearGroupImage(group.id);
```

Display it: each `MarmotGroup` carries `imageHash` / `imageKey` / `imageNonce` (null when unset). Download the blob by hash, then decrypt.

```dart
if (group.imageHash != null) {
  final blob = await downloadFromBlossom(group.imageHash!);
  final imageBytes = await Marmot.decryptGroupImage(
    encryptedData: blob,
    imageHash: group.imageHash!,
    imageKey: group.imageKey!,
    imageNonce: group.imageNonce!,
  );
}
```

### Messages

**Sending.**

```dart
// Plain text
final rumor = await buildUnsignedRumor(npub: npub, content: 'hello world');
final eventJson = await marmot.sendMessage(rumor, group.id);
// Publish eventJson to the group's relays

// Structured payloads (JSON)
final rumor = await buildUnsignedRumor(
  npub: npub,
  content: jsonEncode({'type': 'com.myapp.reaction', 'emoji': '👍'}),
  contentType: 'application/json',
);
await marmot.sendMessage(rumor, group.id);

// Shortcut for structured messages — same as the two calls above
final eventJson = await marmot.sendStructured(npub, group.id, {
  'type': 'com.myapp.reaction',
  'emoji': '👍',
});
```

**Receiving.**

```dart
final MarmotMessage? msg = await marmot.processIncoming(nostrEventJson);
// msg.text         — set for plain text, null for structured
// msg.payloadJson  — set when content-type tag is present (structured)
// msg.contentType  — the content-type tag value (e.g. "application/json")
// msg.senderNpub   — author npub
// msg.timestampSecs — sender timestamp
// msg.media        — List<MarmotMediaRef>, MIP-04 attachments
```

**Retrieving stored messages.** `sendMessage` and `processIncoming` both persist to the encrypted local DB. Use these to read them back:

```dart
// List messages, newest first
final messages = await marmot.getMessages(group.id);

// Paginate
final page2 = await marmot.getMessages(group.id,
  params: MessageListParams(limit: 50, offset: 50));

// Sort by local reception time instead of sender timestamp
final byArrival = await marmot.getMessages(group.id,
  params: MessageListParams(sortByProcessedAt: true));

// Single message by Nostr event ID hex
final msg = await marmot.getMessage(group.id, eventIdHex);

// Most recent message (useful for group list previews)
final last = await marmot.getLastMessage(group.id);
```

Each `MarmotGroup` also carries `lastMessageId`, `lastMessageAtSecs`, and `lastMessageProcessedAtSecs` — updated automatically on every send or receive. Sort your group list by recent activity without fetching messages:

```dart
final groups = await marmot.listGroups();
groups.sort((a, b) =>
    (b.lastMessageAtSecs ?? 0).compareTo(a.lastMessageAtSecs ?? 0));
```

### Media (MIP-04)

Send: encrypt → upload encrypted blob to Blossom → send a kind-9 message carrying an `imeta` tag.

```dart
// 1. Encrypt a file for group sharing
final enc = await marmot.encryptMedia(group.id, fileBytes, 'image/png', 'photo.png');
// enc.encryptedData  — Uint8List to upload to Blossom
// enc.originalHash   — content hash (imeta `x` tag)
// enc.nonce          — encryption nonce (imeta `n` tag)
// enc.blurhash, enc.thumbhash, enc.dimensionsWidth, enc.dimensionsHeight

// 2. Upload enc.encryptedData to Blossom yourself → blob URL
final url = await uploadToBlossom(enc.encryptedData);

// 3. Build the media message and send it
final rumor = await marmot.buildMediaRumor(
  npub: npub,
  groupId: group.id,
  caption: 'check this out',
  url: url,
  originalHash: enc.originalHash,
  mimeType: enc.mimeType,
  filename: enc.filename,
  nonce: enc.nonce,
  blurhash: enc.blurhash,
  thumbhash: enc.thumbhash,
  dimensionsWidth: enc.dimensionsWidth,
  dimensionsHeight: enc.dimensionsHeight,
);
final eventJson = await marmot.sendMessage(rumor, group.id);
```

Receive: `processIncoming` parses each `imeta` tag into `msg.media`. For each ref, download the blob from `ref.url` and decrypt.

```dart
final msg = await marmot.processIncoming(nostrEventJson);
for (final ref in msg!.media) {
  final encryptedBlob = await downloadFromBlossom(ref.url);
  final decrypted = await marmot.decryptMedia(group.id, encryptedBlob, MediaRefInput(
    url: ref.url,
    originalHash: ref.originalHash,
    mimeType: ref.mimeType,       // must match — part of key derivation
    filename: ref.filename,       // must match — part of key derivation
    schemeVersion: ref.schemeVersion,
    nonce: ref.nonce,
  ));
}
```

### Lifecycle

```dart
marmot.dispose(); // remove session, release resources
```

## API overview

### `Marmot` class

One instance per database. All operations that need the encrypted store are instance methods.

**Factories (static):** `Marmot.memory()`, `Marmot.sqlite()`, `Marmot.sqliteWithKey()`, `Marmot.initKeyringStore()`

**Groups:** `createGroup`, `processWelcome`, `getPendingWelcomes`, `acceptWelcome`, `listGroups`, `getMembers`, `addMember`, `removeMember`, `updateGroupMetadata`, `prepareGroupImage` (static), `setGroupImage`, `clearGroupImage`, `decryptGroupImage` (static), `leaveGroup`, `deleteMessagesForGroup`, `deleteGroup`

**Key packages:** `createKeyPackage`, `createSignedKeyPackage`

**Messages:** `sendMessage`, `buildMediaRumor`, `sendStructured`, `processIncoming`, `getMessages`, `getMessage`, `getLastMessage`

**Media:** `encryptMedia`, `decryptMedia`

**Lifecycle:** `dispose()`

### Top-level functions (no `Marmot` instance needed)

- `buildUnsignedRumor({npub, content, contentType?})` — build an unsigned kind-9 rumor
- `signEvent(nsec, unsignedEventJson)` — sign any Nostr event with an nsec

### `MarmotIdentity` class

Static pure functions: `generate()`, `importFromNsec(nsec)`, `validateNsec(nsec)`, `npubFromNsec(nsec)`, `pubkeyHexFromNpub(npub)`

### Models

`StorageConfig`, `NostrKeypair`, `KeyPackageEventData`, `CreateGroupParams`, `GroupCreateResult`, `MarmotGroup`, `MarmotMember`, `PendingWelcome`, `MemberChangeResult`, `GroupMetadataUpdate`, `GroupImagePrepared`, `MarmotMessage`, `MarmotMediaRef`, `MessageListParams`, `EncryptedMediaOutput`, `MediaRefInput`, `MarmotError`

## Architecture

```text
Your Flutter app
   │  (relay WebSocket + Blossom HTTP — your code)
   ▼
marmot_dart  (Dart API)
   │  flutter_rust_bridge (FFI)
   ▼
MDK (Rust)  →  MLS crypto + encrypted SQLite storage
```

`marmot_dart` is transport-agnostic. You subscribe to Nostr events on your relays, feed raw JSON into `processIncoming()` / `processWelcome()`, and publish the encrypted JSON these methods return.

## What this package does NOT do

- Nostr relay WebSocket connections
- Blossom server upload/download
- nsec persistence (use `flutter_secure_storage` or equivalent)
- UI or app-specific logic

## License

MIT — see [LICENSE](LICENSE).
