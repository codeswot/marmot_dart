import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:http/http.dart' as http;

import '../main.dart' show log;

const _blossomServers = [
  'https://blossom.primal.net',
  'https://cdn.nostr.build',
];

const _uploadTimeout = Duration(seconds: 30);
const _downloadTimeout = Duration(seconds: 30);

class BlossomService {
  /// Upload the encrypted blob to all configured servers concurrently
  /// (BUD-02). Returns the URL of the first server to ack; the rest keep
  /// running so the blob is mirrored for redundancy. Returns null if all fail.
  static Future<String?> upload(
    String nsec,
    String pubkeyHex,
    Uint8List data,
  ) async {
    final hash = sha256.convert(data).toString();

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final unsigned = jsonEncode({
      'pubkey': pubkeyHex,
      'created_at': now,
      'kind': 24242,
      'tags': [
        ['t', 'upload'],
        ['x', hash],
        ['expiration', (now + 3600).toString()],
      ],
      'content': 'Upload file',
    });
    final signed = await signEvent(nsec, unsigned);
    final authBase64 = base64Encode(utf8.encode(signed));

    final firstSuccess = Completer<String?>();
    var pending = _blossomServers.length;
    for (final server in _blossomServers) {
      _putBlob(server, authBase64, data).then((ok) {
        if (ok && !firstSuccess.isCompleted) {
          log('Blossom upload OK: $server ($hash)');
          firstSuccess.complete('$server/$hash');
        }
      }).whenComplete(() {
        if (--pending == 0 && !firstSuccess.isCompleted) {
          firstSuccess.complete(null);
        }
      });
    }
    return firstSuccess.future;
  }

  static Future<bool> _putBlob(
    String server,
    String authBase64,
    Uint8List data,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$server/upload'),
            headers: {
              'Authorization': 'Nostr $authBase64',
              'Content-Type': 'application/octet-stream',
            },
            body: data,
          )
          .timeout(_uploadTimeout);
      if (response.statusCode ~/ 100 == 2 && response.body.contains('sha256')) {
        return true;
      }
      log('Blossom $server returned ${response.statusCode}: ${response.body}');
      return false;
    } catch (e) {
      log('Blossom $server error: $e');
      return false;
    }
  }

  /// Download a blob given a full Blossom URL or a bare SHA-256 hash. Tries the
  /// canonical URL first, then falls back to the other servers by hash (BUD-01).
  static Future<Uint8List?> download(String urlOrHash) async {
    final hash = urlOrHash.contains('/')
        ? urlOrHash.split('/').last.split('.').first
        : urlOrHash;
    final candidates = <String>[
      if (urlOrHash.startsWith('http')) urlOrHash,
      for (final server in _blossomServers) '$server/$hash',
    ];
    final tried = <String>{};
    for (final url in candidates) {
      if (!tried.add(url)) continue;
      try {
        final response =
            await http.get(Uri.parse(url)).timeout(_downloadTimeout);
        if (response.statusCode == 200) {
          log('Blossom download OK: $url');
          return response.bodyBytes;
        }
      } catch (e) {
        log('Blossom download error ($url): $e');
      }
    }
    return null;
  }
}
