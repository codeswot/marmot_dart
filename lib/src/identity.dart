import 'rust/api/identity.dart' as g;
import '_ensure.dart';

class MarmotIdentity {
  MarmotIdentity._();

  /// Generate a new Nostr keypair. Pure function — no MDK state needed.
  /// Host app should persist the nsec via flutter_secure_storage.
  static Future<g.NostrKeypair> generate() async {
    await ensureNativeLibrary();
    return g.generate();
  }

  /// Parse an nsec and return the full keypair. Pure function.
  static Future<g.NostrKeypair> importFromNsec(String nsec) async {
    await ensureNativeLibrary();
    return g.importFromNsec(nsec: nsec);
  }

  /// Validate an nsec string. Pure function.
  static Future<bool> validateNsec(String nsec) async {
    await ensureNativeLibrary();
    return g.validateNsec(nsec: nsec);
  }

  /// Derive the npub from an nsec. Pure function.
  static Future<String> npubFromNsec(String nsec) async {
    await ensureNativeLibrary();
    return g.npubFromNsec(nsec: nsec);
  }

  /// Convert a bech32 npub to hex pubkey. Useful for Nostr relay filters.
  static Future<String> pubkeyHexFromNpub(String npub) async {
    await ensureNativeLibrary();
    return g.pubkeyHexFromNpub(npub: npub);
  }
}
