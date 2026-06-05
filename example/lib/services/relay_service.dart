import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nostr_core_dart/nostr.dart' show Filter;

import '../main.dart' show log;

const _relays = [
  'wss://relay.damus.io',
  'wss://nos.lol',
  'wss://relay.primal.net',
];

class RelayService {
  /// Publish to all relays in parallel.
  static Future<int> publish(String signedJson) async {
    final sw = Stopwatch()..start();
    final results = await Future.wait(_relays.map((url) => _publishOne(url, signedJson)));
    final ok = results.where((r) => r).length;
    log('PUB  → $ok/${_relays.length} relays (${sw.elapsedMilliseconds}ms)');
    return ok;
  }

  static Future<bool> _publishOne(String url, String json) async {
    try {
      final sw = Stopwatch()..start();
      final ws = await WebSocket.connect(url);
      final c = Completer<bool>();
      ws.listen((d) {
        final m = jsonDecode(d as String) as List;
        if (m[0] == 'OK') c.complete(m[2] == true);
        if (m[0] == 'NOTICE') log('  PUB $url NOTICE: ${m[1]}');
      }, onError: (_) { if (!c.isCompleted) c.complete(false); });
      ws.add(jsonEncode(['EVENT', jsonDecode(json)]));
      final ok = await c.future.timeout(const Duration(seconds: 5));
      await ws.close();
      log('  PUB $url → ${ok ? 'OK' : 'FAIL'} (${sw.elapsedMilliseconds}ms)');
      return ok;
    } catch (e) {
      log('  PUB $url → ERR: $e');
      return false;
    }
  }

  /// Query all relays in parallel, deduplicate by event ID.
  static Future<List<Map<String, dynamic>>> query(List<Filter> filters) async {
    final sw = Stopwatch()..start();
    final filterJson = filters.map((f) => f.toJson()).toList();
    final req = jsonEncode(['REQ', 'q', ...filterJson]);
    log('QRY REQ: $req');

    final all = <String, Map<String, dynamic>>{};
    final results = await Future.wait(_relays.map((url) => _queryOne(url, req)));
    for (final r in results) {
      all.addAll(r);
    }
    log('QRY  → ${all.length} events (${sw.elapsedMilliseconds}ms)');
    return all.values.toList();
  }

  static Future<Map<String, Map<String, dynamic>>> _queryOne(String url, String reqJson) async {
    final all = <String, Map<String, dynamic>>{};
    try {
      final sw = Stopwatch()..start();
      final ws = await WebSocket.connect(url);
      final c = Completer<void>();
      ws.listen((d) {
        final m = jsonDecode(d as String) as List;
        if (m[0] == 'EVENT') {
          final e = m[2] as Map<String, dynamic>;
          all[e['id'] as String] = e;
        }
        if (m[0] == 'EOSE') { ws.close(); c.complete(); }
      }, onError: (_) { if (!c.isCompleted) c.complete(); },
         onDone: () { if (!c.isCompleted) c.complete(); });
      ws.add(reqJson);
      await c.future.timeout(const Duration(seconds: 5));
      log('  QRY $url → ${all.length} events (${sw.elapsedMilliseconds}ms)');
    } catch (e) {
      log('  QRY $url → ERR: $e');
    }
    return all;
  }
}
