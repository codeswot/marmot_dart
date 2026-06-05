import 'dart:typed_data';
import 'rust/api/media.dart' as g;
import '_ensure.dart';

Future<g.EncryptedMediaOutput> encryptMedia(
  String dbPath,
  String groupId,
  Uint8List data,
  String mimeType,
  String filename,
) async {
  await ensureNativeLibrary();
  return g.encryptMedia(
    dbPath: dbPath,
    groupId: groupId,
    data: data,
    mimeType: mimeType,
    filename: filename,
  );
}

Future<Uint8List> decryptMedia(
  String dbPath,
  String groupId,
  Uint8List encryptedData,
  g.MediaRefInput mediaRef,
) async {
  await ensureNativeLibrary();
  return g.decryptMedia(
    dbPath: dbPath,
    groupId: groupId,
    encryptedData: encryptedData,
    mediaRef: mediaRef,
  );
}
