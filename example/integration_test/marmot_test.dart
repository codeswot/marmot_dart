import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:path/path.dart' as p;

Uint8List _random32Bytes() {
  final bytes = Uint8List(32);
  final rng = Random.secure();
  for (var i = 0; i < 32; i++) {
    bytes[i] = rng.nextInt(256);
  }
  return bytes;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Marmot marmot;

  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('marmot_dart_it');
    marmot = await Marmot.sqliteWithKey(
      dbPath: p.join(dir.path, 'marmot.db'),
      dbKey: _random32Bytes(),
    );
  });

  testWidgets('generates a keypair and validates nsec', (_) async {
    final keypair = await MarmotIdentity.generate();
    expect(keypair.npub, startsWith('npub1'));
    expect(keypair.nsec, isNotNull);
    expect(keypair.pubkeyHex, isNotEmpty);
  });

  testWidgets('rejects an invalid nsec', (_) async {
    expect(await MarmotIdentity.validateNsec('not-an-nsec'), isFalse);
  });
}
