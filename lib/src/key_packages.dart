import 'rust/api/key_packages.dart' as g;
import '_ensure.dart';

Future<g.KeyPackageEventData> createKeyPackage(String dbPath, String npub, List<String> relayUrls) async {
  await ensureNativeLibrary();
  return g.create(dbPath: dbPath, npub: npub, relayUrls: relayUrls);
}

Future<String> createSignedKeyPackage(String dbPath, String nsec, List<String> relayUrls) async {
  await ensureNativeLibrary();
  return g.createSignedEvent(dbPath: dbPath, nsec: nsec, relayUrls: relayUrls);
}

Future<String> signEvent(String nsec, String unsignedEventJson) async {
  await ensureNativeLibrary();
  return g.signEvent(nsec: nsec, unsignedEventJson: unsignedEventJson);
}
