import 'rust/api/key_packages.dart' as g;
import '_ensure.dart';

Future<g.KeyPackageEventData> createKeyPackage(
  String dbPath,
  String npub,
  List<String> relayUrls,
) async {
  await ensureNativeLibrary();
  return g.create(dbPath: dbPath, npub: npub, relayUrls: relayUrls);
}

Future<String> createSignedKeyPackage(
  String dbPath,
  String nsec,
  List<String> relayUrls,
) async {
  await ensureNativeLibrary();
  return g.createSignedEvent(dbPath: dbPath, nsec: nsec, relayUrls: relayUrls);
}

/// Sign an unsigned Nostr event JSON with [nsec] and return the signed event
/// JSON. A convenience for assembling events the host app builds itself.
Future<String> signEvent(String nsec, String unsignedEventJson) async {
  await ensureNativeLibrary();
  return g.signEvent(nsec: nsec, unsignedEventJson: unsignedEventJson);
}
