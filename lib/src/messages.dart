import 'rust/api/messages.dart' as g;
import '_ensure.dart';

Future<String> buildUnsignedRumor(String npub, String content) async {
  await ensureNativeLibrary();
  return g.buildUnsignedRumor(npub: npub, content: content);
}

Future<String> sendMessage(
  String dbPath,
  String unsignedRumorJson,
  String groupId,
) async {
  await ensureNativeLibrary();
  return g.send(
    dbPath: dbPath,
    unsignedRumorJson: unsignedRumorJson,
    groupId: groupId,
  );
}

Future<g.MarmotMessage?> processIncoming(
  String dbPath,
  String nostrEventJson,
) async {
  await ensureNativeLibrary();
  return g.processIncoming(dbPath: dbPath, nostrEventJson: nostrEventJson);
}
