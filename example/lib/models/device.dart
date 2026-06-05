import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:marmot_dart/marmot_dart.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Device {
  final String name;
  late final Marmot marmot;
  NostrKeypair? keypair;

  Device(this.name);

  Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    final dp = p.join(dir.path, 'marmot_${name.toLowerCase()}.db');

    final prefs = await SharedPreferences.getInstance();
    final keyName = 'db_key_${name.toLowerCase()}';

    var keyB64 = prefs.getString(keyName);
    if (keyB64 == null) {
      keyB64 = base64Encode(_rand32());
      await prefs.setString(keyName, keyB64);
    }

    final key = base64Decode(keyB64);
    marmot = await Marmot.sqliteWithKey(dbPath: dp, dbKey: key);
  }

  String get npub => keypair?.npub ?? '';
  String get nsec => keypair?.nsec ?? '';
  String get hex => keypair?.pubkeyHex ?? '';
  bool get hasIdentity => keypair != null;

  Uint8List _rand32() {
    final b = Uint8List(32);
    final r = Random.secure();
    for (var i = 0; i < 32; i++) {
      b[i] = r.nextInt(256);
    }
    return b;
  }

  void dispose() => marmot.dispose();
}
