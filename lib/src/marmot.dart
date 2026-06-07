import 'dart:convert';
import 'dart:typed_data';

import 'rust/api/init.dart' as init;
import 'rust/api/groups.dart' as groups;
import 'rust/api/messages.dart' as messages;
import 'rust/api/key_packages.dart' as key_packages;
import 'rust/api/media.dart' as media;
import 'rust/state.dart';
import '_ensure.dart';

/// Build an unsigned kind-9 group-message rumor. A pure function — no
/// [Marmot] instance needed. Use [Marmot.sendMessage] to encrypt it.
///
/// Set [contentType] (e.g. `"application/json"`) for structured payloads —
/// the receiver's [MarmotMessage] will populate [MarmotMessage.payloadJson]
/// instead of [MarmotMessage.text].
Future<String> buildUnsignedRumor({
  required String npub,
  required String content,
  String? contentType,
}) async {
  await ensureNativeLibrary();
  return messages.buildUnsignedRumor(
    npub: npub,
    content: content,
    contentType: contentType,
  );
}

/// Sign an unsigned Nostr event JSON with an nsec. A pure function — no
/// [Marmot] instance needed. Returns the signed event JSON.
Future<String> signEvent(String nsec, String unsignedEventJson) async {
  await ensureNativeLibrary();
  return key_packages.signEvent(nsec: nsec, unsignedEventJson: unsignedEventJson);
}

/// Entry point to the marmot_dart API.
///
/// One [Marmot] instance is bound to a single encrypted database at [dbPath].
/// Construct it with one of the factory constructors ([memory], [sqlite],
/// [sqliteWithKey]) and use the instance methods for groups, key packages,
/// messages and media. Identity helpers live on [MarmotIdentity].
class Marmot {
  /// Absolute path to the SQLite database backing this instance.
  final String dbPath;

  Marmot._({required this.dbPath});

  // ---------------------------------------------------------------------------
  // Factories
  // ---------------------------------------------------------------------------

  /// Initialise the OS keyring store. Call once before [sqlite].
  static Future<void> initKeyringStore() => init.initKeyringStore();

  /// In-memory storage — ephemeral, for testing.
  static Future<Marmot> memory({required String dbPath}) async {
    await ensureNativeLibrary();
    await init.initMdk(dbPath: dbPath, storage: const StorageConfig.memory());
    return Marmot._(dbPath: dbPath);
  }

  /// Keyring-managed SQLite storage.
  /// Call [initKeyringStore] once before using this constructor.
  static Future<Marmot> sqlite({
    required String dbPath,
    required String serviceId,
    required String keyId,
  }) async {
    await ensureNativeLibrary();
    await init.initMdk(
      dbPath: dbPath,
      storage: StorageConfig.sqlite(
        dbPath: dbPath,
        serviceId: serviceId,
        keyId: keyId,
      ),
    );
    return Marmot._(dbPath: dbPath);
  }

  /// SQLite storage with a host-supplied 32-byte encryption key.
  static Future<Marmot> sqliteWithKey({
    required String dbPath,
    required Uint8List dbKey,
  }) async {
    await ensureNativeLibrary();
    await init.initMdk(
      dbPath: dbPath,
      storage: StorageConfig.sqliteWithKey(dbPath: dbPath, dbKey: dbKey),
    );
    return Marmot._(dbPath: dbPath);
  }

  // ---------------------------------------------------------------------------
  // Groups
  // ---------------------------------------------------------------------------

  /// Create a new MLS group. Returns the group plus one welcome rumor per
  /// invited member (gift-wrap and send each over Nostr).
  Future<groups.GroupCreateResult> createGroup(
    String creatorNpub,
    groups.CreateGroupParams params,
  ) => groups.create(dbPath: dbPath, creatorNpub: creatorNpub, params: params);

  /// Validate and store an incoming welcome rumor as a pending invite.
  Future<void> processWelcome(String wrapperEventId, String welcomeRumorJson) =>
      groups.processWelcome(
        dbPath: dbPath,
        wrapperEventId: wrapperEventId,
        welcomeRumorJson: welcomeRumorJson,
      );

  /// List welcomes that have been processed but not yet accepted.
  Future<List<groups.PendingWelcome>> getPendingWelcomes() =>
      groups.getPendingWelcomes(dbPath: dbPath);

  /// Accept a pending welcome (by its id) and join the group.
  Future<void> acceptWelcome(String welcomeId) =>
      groups.acceptWelcome(dbPath: dbPath, welcomeId: welcomeId);

  /// List all groups this identity is a member of.
  Future<List<groups.MarmotGroup>> listGroups() => groups.list(dbPath: dbPath);

  /// List the members of a group.
  Future<List<groups.MarmotMember>> getMembers(String groupId) =>
      groups.getMembers(dbPath: dbPath, groupId: groupId);

  /// Add a member from their published key-package event. Returns the commit
  /// event plus the welcome rumor(s) to deliver to the new member.
  Future<groups.MemberChangeResult> addMember(
    String groupId,
    String keyPackageEventJson,
  ) => groups.addMember(
    dbPath: dbPath,
    groupId: groupId,
    keyPackageEventJson: keyPackageEventJson,
  );

  /// Remove a member by npub. Returns the commit event to publish.
  Future<groups.MemberChangeResult> removeMember(String groupId, String npub) =>
      groups.removeMember(dbPath: dbPath, groupId: groupId, npub: npub);

  /// Edit group metadata (name / description / relays / admins). Only the
  /// fields you pass are changed. Returns the kind:445 commit event JSON to
  /// publish to the group's relays.
  Future<String> updateGroupMetadata(
    String groupId, {
    String? name,
    String? description,
    List<String>? relayUrls,
    List<String>? adminNpubs,
  }) => groups.updateGroupMetadata(
    dbPath: dbPath,
    groupId: groupId,
    update: groups.GroupMetadataUpdate(
      name: name,
      description: description,
      relayUrls: relayUrls,
      adminNpubs: adminNpubs,
    ),
  );

  /// Encrypt a group image for upload. Upload [GroupImagePrepared.encryptedData]
  /// to Blossom authenticating with [GroupImagePrepared.uploadNsec], then call
  /// [setGroupImage] with the returned hash/key/nonce/uploadKey.
  static Future<groups.GroupImagePrepared> prepareGroupImage(
    Uint8List imageData,
    String mimeType,
  ) async {
    await ensureNativeLibrary();
    return groups.prepareGroupImage(imageData: imageData, mimeType: mimeType);
  }

  /// Set the group image in group metadata. Returns the kind:445 commit event
  /// JSON to publish to the group's relays.
  Future<String> setGroupImage(
    String groupId, {
    required Uint8List imageHash,
    required Uint8List imageKey,
    required Uint8List imageNonce,
    required Uint8List imageUploadKey,
  }) => groups.setGroupImage(
    dbPath: dbPath,
    groupId: groupId,
    imageHash: imageHash,
    imageKey: imageKey,
    imageNonce: imageNonce,
    imageUploadKey: imageUploadKey,
  );

  /// Remove the group image. Returns the kind:445 commit event JSON to publish.
  Future<String> clearGroupImage(String groupId) =>
      groups.clearGroupImage(dbPath: dbPath, groupId: groupId);

  /// Decrypt a downloaded group-image blob using the hash/key/nonce from
  /// [MarmotGroup.imageHash] / [MarmotGroup.imageKey] / [MarmotGroup.imageNonce].
  static Future<Uint8List> decryptGroupImage({
    required Uint8List encryptedData,
    required Uint8List imageHash,
    required Uint8List imageKey,
    required Uint8List imageNonce,
  }) async {
    await ensureNativeLibrary();
    return groups.decryptGroupImageBlob(
      encryptedData: encryptedData,
      imageHash: imageHash,
      imageKey: imageKey,
      imageNonce: imageNonce,
    );
  }

  // ---------------------------------------------------------------------------
  // Key packages
  // ---------------------------------------------------------------------------

  /// Mint an MLS key package. Returns the pieces to assemble, sign and publish
  /// a kind:30443 event yourself.
  Future<key_packages.KeyPackageEventData> createKeyPackage(
    String npub,
    List<String> relayUrls,
  ) => key_packages.create(dbPath: dbPath, npub: npub, relayUrls: relayUrls);

  /// Mint a key package and return a fully signed kind:30443 event, ready to
  /// publish.
  Future<String> createSignedKeyPackage(String nsec, List<String> relayUrls) =>
      key_packages.createSignedEvent(
        dbPath: dbPath,
        nsec: nsec,
        relayUrls: relayUrls,
      );

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  /// Encrypt an unsigned rumor for the group. Returns the kind:445 event JSON
  /// to publish to the group's relays.
  Future<String> sendMessage(String unsignedRumorJson, String groupId) =>
      messages.send(
        dbPath: dbPath,
        unsignedRumorJson: unsignedRumorJson,
        groupId: groupId,
      );

  /// Build a kind-9 media-message rumor carrying a MIP-04 `imeta` tag. Encrypt
  /// the file with [encryptMedia] and upload the blob to Blossom first.
  Future<String> buildMediaRumor({
    required String npub,
    required String groupId,
    required String caption,
    required String url,
    required Uint8List originalHash,
    required String mimeType,
    required String filename,
    required Uint8List nonce,
    String? blurhash,
    String? thumbhash,
    int? dimensionsWidth,
    int? dimensionsHeight,
  }) => messages.buildMediaRumor(
    dbPath: dbPath,
    npub: npub,
    groupId: groupId,
    caption: caption,
    url: url,
    originalHash: originalHash,
    mimeType: mimeType,
    filename: filename,
    nonce: nonce,
    blurhash: blurhash,
    thumbhash: thumbhash,
    dimensionsWidth: dimensionsWidth,
    dimensionsHeight: dimensionsHeight,
  );

  /// Convenience: build a structured rumor with [contentType] "application/json",
  /// encrypt it, and return the signed kind:445 event JSON to publish.
  /// Equivalent to [buildUnsignedRumor] + [sendMessage].
  Future<String> sendStructured(
    String npub,
    String groupId,
    Map<String, dynamic> payload,
  ) async {
    final rumor = await messages.buildUnsignedRumor(
      npub: npub,
      content: jsonEncode(payload),
      contentType: 'application/json',
    );
    return messages.send(
      dbPath: dbPath,
      unsignedRumorJson: rumor,
      groupId: groupId,
    );
  }

  /// Decrypt and apply an incoming Nostr event. Returns the decoded message
  /// (including any [MarmotMessage.media]) for application messages, or null for
  /// non-application events (e.g. commits, which are still applied).
  Future<messages.MarmotMessage?> processIncoming(String nostrEventJson) =>
      messages.processIncoming(dbPath: dbPath, nostrEventJson: nostrEventJson);

  /// List stored messages for a group, newest first. Paginate with
  /// [MessageListParams].
  Future<List<messages.MarmotMessage>> getMessages(
    String groupId, {
    messages.MessageListParams? params,
  }) => messages.getMessages(dbPath: dbPath, groupId: groupId, params: params);

  /// Look up a single stored message by its Nostr event ID hex.
  Future<messages.MarmotMessage?> getMessage(
    String groupId,
    String eventIdHex,
  ) => messages.getMessage(
    dbPath: dbPath,
    groupId: groupId,
    eventIdHex: eventIdHex,
  );

  /// Return the most recent message in a group, or null if empty.
  Future<messages.MarmotMessage?> getLastMessage(String groupId) =>
      messages.getLastMessage(dbPath: dbPath, groupId: groupId);

  // ---------------------------------------------------------------------------
  // Media
  // ---------------------------------------------------------------------------

  /// Encrypt a file for the group (MIP-04). Upload the returned
  /// [EncryptedMediaOutput.encryptedData] to Blossom, then [buildMediaRumor].
  Future<media.EncryptedMediaOutput> encryptMedia(
    String groupId,
    Uint8List data,
    String mimeType,
    String filename,
  ) => media.encryptMedia(
    dbPath: dbPath,
    groupId: groupId,
    data: data,
    mimeType: mimeType,
    filename: filename,
  );

  /// Decrypt a downloaded media blob using a [MediaRefInput] built from a
  /// received [MarmotMediaRef]. `mimeType` and `filename` must match the
  /// originals — they are part of the key derivation.
  Future<Uint8List> decryptMedia(
    String groupId,
    Uint8List encryptedData,
    media.MediaRefInput mediaRef,
  ) => media.decryptMedia(
    dbPath: dbPath,
    groupId: groupId,
    encryptedData: encryptedData,
    mediaRef: mediaRef,
  );

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Release this session's resources and remove it from the session registry.
  void dispose() {
    init.removeSession(dbPath: dbPath);
  }
}
