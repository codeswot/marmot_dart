import 'dart:typed_data';

import 'rust/api/init.dart' as init;
import 'rust/api/groups.dart' as groups;
import 'rust/api/messages.dart' as messages;
import 'rust/api/key_packages.dart' as key_packages;
import 'rust/api/media.dart' as media;
import 'rust/state.dart';
import '_ensure.dart';

class Marmot {
  final String dbPath;

  Marmot._({required this.dbPath});

  // ---------------------------------------------------------------------------
  // Factories
  // ---------------------------------------------------------------------------

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

  Future<groups.GroupCreateResult> createGroup(
    String creatorNpub,
    groups.CreateGroupParams params,
  ) => groups.create(dbPath: dbPath, creatorNpub: creatorNpub, params: params);

  Future<void> processWelcome(String wrapperEventId, String welcomeRumorJson) =>
      groups.processWelcome(
        dbPath: dbPath,
        wrapperEventId: wrapperEventId,
        welcomeRumorJson: welcomeRumorJson,
      );

  Future<List<groups.PendingWelcome>> getPendingWelcomes() =>
      groups.getPendingWelcomes(dbPath: dbPath);

  Future<void> acceptWelcome(String welcomeId) =>
      groups.acceptWelcome(dbPath: dbPath, welcomeId: welcomeId);

  Future<List<groups.MarmotGroup>> listGroups() => groups.list(dbPath: dbPath);

  Future<List<groups.MarmotMember>> getMembers(String groupId) =>
      groups.getMembers(dbPath: dbPath, groupId: groupId);

  Future<groups.MemberChangeResult> addMember(
    String groupId,
    String keyPackageEventJson,
  ) => groups.addMember(
    dbPath: dbPath,
    groupId: groupId,
    keyPackageEventJson: keyPackageEventJson,
  );

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

  Future<key_packages.KeyPackageEventData> createKeyPackage(
    String npub,
    List<String> relayUrls,
  ) => key_packages.create(dbPath: dbPath, npub: npub, relayUrls: relayUrls);

  Future<String> createSignedKeyPackage(String nsec, List<String> relayUrls) =>
      key_packages.createSignedEvent(
        dbPath: dbPath,
        nsec: nsec,
        relayUrls: relayUrls,
      );

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  Future<String> sendMessage(String unsignedRumorJson, String groupId) =>
      messages.send(
        dbPath: dbPath,
        unsignedRumorJson: unsignedRumorJson,
        groupId: groupId,
      );

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

  Future<messages.MarmotMessage?> processIncoming(String nostrEventJson) =>
      messages.processIncoming(dbPath: dbPath, nostrEventJson: nostrEventJson);

  // ---------------------------------------------------------------------------
  // Media
  // ---------------------------------------------------------------------------

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

  void dispose() {
    init.removeSession(dbPath: dbPath);
  }
}
