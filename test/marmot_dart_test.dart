import 'package:flutter_test/flutter_test.dart';
import 'package:marmot_dart/marmot_dart.dart';

void main() {
  group('exported models', () {
    test('CreateGroupParams holds its fields', () {
      const params = CreateGroupParams(
        name: 'Team',
        description: 'A private team',
        relayUrls: ['wss://relay.example.com'],
        memberKeyPackageEventJsons: ['{}'],
      );

      expect(params.name, 'Team');
      expect(params.relayUrls, hasLength(1));
      expect(params.memberKeyPackageEventJsons, ['{}']);
    });

    test('NostrKeypair exposes only public parts when nsec is null', () {
      const keypair = NostrKeypair(
        npub: 'npub1example',
        nsec: null,
        pubkeyHex: 'deadbeef',
      );

      expect(keypair.nsec, isNull);
      expect(keypair.npub, 'npub1example');
      expect(keypair.pubkeyHex, 'deadbeef');
    });
  });
}
