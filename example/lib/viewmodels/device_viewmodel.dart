import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:marmot_dart/marmot_dart.dart';

import '../models/device.dart';
import 'package:nostr_core_dart/nostr.dart';
import '../services/relay_service.dart';
import '../main.dart' show log;

class DeviceViewModel extends ChangeNotifier {
  final Device device;
  String status = '';
  String? lastWelcome;
  List<MarmotGroup> groups = [];
  List<Map<String, String>> fetchedWelcomes = [];

  DeviceViewModel(this.device);

  String get name => device.name;
  String get npub => device.npub;
  String get nsec => device.nsec;
  String get hex => device.hex;
  bool get hasIdentity => device.hasIdentity;

  Future<void> reloadGroups() async {
    groups = await device.marmot.listGroups();
    notifyListeners();
  }

  Future<void> generate() async {
    device.keypair = await MarmotIdentity.generate();
    log('$name: generated ${npub.substring(0, 12)}...');
    notifyListeners();
  }

  Future<void> importNsec(String nsec) async {
    final n = nsec.trim();
    if (n.isEmpty || !await MarmotIdentity.validateNsec(n)) return;
    device.keypair = await MarmotIdentity.importFromNsec(n);
    log('$name: imported ${npub.substring(0, 12)}...');
    notifyListeners();
  }

  Future<void> publishKeyPackage() async {
    if (!hasIdentity) return;
    final signed = await device.marmot.createSignedKeyPackage(nsec, const [
      'wss://relay.damus.io',
    ]);
    final ok = await RelayService.publish(signed);
    status = 'Published to $ok relays';
    notifyListeners();
  }

  Future<String?> doCreateGroup(
    String groupName,
    List<String> memberNpubs,
  ) async {
    if (!hasIdentity) return null;
    final hex = <String>[];
    for (final n in memberNpubs) {
      try {
        hex.add(await MarmotIdentity.pubkeyHexFromNpub(n));
      } catch (_) {
        hex.add(n);
      }
    }
    final kpEvents = await RelayService.query([
      Filter(kinds: const [30443], authors: hex, limit: memberNpubs.length),
    ]);
    final kps = kpEvents.map((e) => jsonEncode(e)).toList();
    log('$name: got ${kps.length} key packages');
    if (kps.isNotEmpty) log('First KP preview: ${kps.first.substring(0, 200)}');

    final r = await device.marmot.createGroup(
      npub,
      CreateGroupParams(
        name: groupName,
        description: '',
        relayUrls: const ['wss://relay.damus.io'],
        memberKeyPackageEventJsons: kps,
      ),
    );

    for (var i = 0; i < r.welcomeRumors.length && i < memberNpubs.length; i++) {
      final inviteeHex = hex[i];
      final unsigned = jsonEncode({
        'pubkey': device.hex,
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'kind': 9,
        'tags': [
          ['p', inviteeHex],
        ],
        'content': r.welcomeRumors[i],
      });
      final signed = await signEvent(nsec, unsigned);
      await RelayService.publish(signed);
    }
    lastWelcome = r.welcomeRumors.isNotEmpty ? r.welcomeRumors.first : null;
    await reloadGroups();
    log('$name: group created (${r.group.memberCount} members)');
    status = 'Created';
    notifyListeners();
    return r.group.id;
  }

  Future<void> fetchWelcomes() async {
    if (!hasIdentity) return;
    final events = await RelayService.query([
      Filter(kinds: const [9], p: [hex], limit: 20),
    ]);
    fetchedWelcomes = events
        .map(
          (e) => {
            'id': e['id'] as String? ?? '',
            'rumor': (e['content'] as String?) ?? jsonEncode(e),
          },
        )
        .toList();
    log('$name: found ${fetchedWelcomes.length} welcome(s)');
    notifyListeners();
  }

  Future<void> joinWelcome(String eventId, String rumorJson) async {
    await device.marmot.processWelcome(eventId, rumorJson);
    final w = await device.marmot.getPendingWelcomes();
    if (w.isNotEmpty) await device.marmot.acceptWelcome(w.first.id);
    await reloadGroups();
    fetchedWelcomes = [];
    log('$name: joined group');
    status = 'Joined';
    notifyListeners();
  }
}
