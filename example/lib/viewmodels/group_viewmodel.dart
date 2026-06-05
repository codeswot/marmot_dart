import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:marmot_dart/marmot_dart.dart';
import 'package:path_provider/path_provider.dart';

import '../models/device.dart';
import '../models/chat_message.dart';
import 'package:nostr_core_dart/nostr.dart';
import '../services/blossom_service.dart';
import '../services/relay_service.dart';
import '../main.dart' show log;

class GroupViewModel extends ChangeNotifier {
  final Device device;
  MarmotGroup group;
  final List<ChatMessage> messages = [];

  // url -> saved path, so download state survives a refresh().
  final Map<String, String> _downloaded = {};

  Uint8List? imageBytes;
  bool busy = false;

  GroupViewModel(this.device, this.group) {
    loadGroupImage();
  }

  String get name => group.name;
  String get description => group.description;
  int get memberCount => group.memberCount;
  String get id => group.id;

  /// Re-fetch this group's stored metadata (name/description/image) after a
  /// local edit or after a received commit was applied.
  Future<void> refreshGroup() async {
    final groups = await device.marmot.listGroups();
    final found = groups.where((g) => g.id == group.id);
    if (found.isNotEmpty) group = found.first;
    await loadGroupImage();
    notifyListeners();
  }

  Future<void> editGroup({String? name, String? description}) async {
    final n = (name != null && name.trim().isNotEmpty) ? name.trim() : null;
    final d = (description != null && description.trim().isNotEmpty) ? description.trim() : null;
    if (n == null && d == null) return;
    busy = true;
    notifyListeners();
    try {
      final ev = await device.marmot.updateGroupMetadata(group.id, name: n, description: d);
      await RelayService.publish(ev);
      log('${device.name}: group metadata updated');
      await refreshGroup();
    } catch (e) {
      log('Edit group error: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> doSetGroupImage() async {
    busy = true;
    notifyListeners();
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result == null || result.files.isEmpty || result.files.first.path == null) return;
      final file = result.files.first;
      final bytes = await File(file.path!).readAsBytes();
      final mime = _mimeType(file.extension ?? 'png');

      final prep = await Marmot.prepareGroupImage(bytes, mime);
      // Upload authenticating with the derived one-time keypair, not the user's nsec.
      final url = await BlossomService.upload(prep.uploadNsec, prep.uploadPubkeyHex, prep.encryptedData);
      if (url == null) {
        log('${device.name}: group image upload failed');
        return;
      }
      final ev = await device.marmot.setGroupImage(
        group.id,
        imageHash: prep.imageHash,
        imageKey: prep.imageKey,
        imageNonce: prep.imageNonce,
        imageUploadKey: prep.imageUploadKey,
      );
      await RelayService.publish(ev);
      log('${device.name}: group image set');
      await refreshGroup();
    } catch (e) {
      log('Set group image error: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> clearGroupImage() async {
    busy = true;
    notifyListeners();
    try {
      final ev = await device.marmot.clearGroupImage(group.id);
      await RelayService.publish(ev);
      imageBytes = null;
      log('${device.name}: group image cleared');
      await refreshGroup();
    } catch (e) {
      log('Clear group image error: $e');
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> loadGroupImage() async {
    final hash = group.imageHash, key = group.imageKey, nonce = group.imageNonce;
    if (hash == null || key == null || nonce == null) {
      imageBytes = null;
      return;
    }
    try {
      final enc = await BlossomService.download(_hex(hash));
      if (enc == null) return;
      imageBytes = await Marmot.decryptGroupImage(
        encryptedData: enc,
        imageHash: hash,
        imageKey: key,
        imageNonce: nonce,
      );
      notifyListeners();
    } catch (e) {
      log('Load group image error: $e');
    }
  }

  String _hex(Uint8List b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

  Future<void> doSendMessage(String text) async {
    if (!device.hasIdentity || text.trim().isEmpty) return;
    final rumor = await buildUnsignedRumor(device.npub, text);
    final ev = await device.marmot.sendMessage(rumor, group.id);
    await RelayService.publish(ev);
    messages.add(ChatMessage.text(sender: device.name, isMine: true, text: text));
    log('${device.name}: message published');
    notifyListeners();
  }

  Future<void> doSendFile(String caption) async {
    if (!device.hasIdentity) return;
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;

      final bytes = await File(file.path!).readAsBytes();
      final mime = _mimeType(file.extension ?? 'bin');
      final name = file.name;

      log('${device.name}: encrypting $name (${bytes.length}B, $mime)...');
      final r = await device.marmot.encryptMedia(group.id, bytes, mime, name);
      log('${device.name}: encrypted ${r.originalSize.toInt()}B -> ${r.encryptedSize.toInt()}B');

      final url = await BlossomService.upload(device.nsec, device.hex, r.encryptedData);
      if (url == null) {
        messages.add(ChatMessage.text(
          sender: device.name,
          isMine: true,
          text: '[ERROR] Blossom upload failed',
        ));
        notifyListeners();
        return;
      }

      final rumor = await device.marmot.buildMediaRumor(
        npub: device.npub,
        groupId: group.id,
        caption: caption,
        url: url,
        originalHash: r.originalHash,
        mimeType: r.mimeType,
        filename: r.filename,
        nonce: r.nonce,
        blurhash: r.blurhash,
        thumbhash: r.thumbhash,
        dimensionsWidth: r.dimensionsWidth,
        dimensionsHeight: r.dimensionsHeight,
      );
      final ev = await device.marmot.sendMessage(rumor, group.id);
      await RelayService.publish(ev);
      log('${device.name}: file published via Blossom ($url)');

      final ref = MarmotMediaRef(
        url: url,
        originalHash: r.originalHash,
        mimeType: r.mimeType,
        filename: r.filename,
        schemeVersion: 'mip04-v2',
        nonce: r.nonce,
        dimensionsWidth: r.dimensionsWidth,
        dimensionsHeight: r.dimensionsHeight,
      );
      messages.add(ChatMessage.file(
        sender: device.name,
        isMine: true,
        media: ref,
        text: caption.trim().isEmpty ? null : caption,
        status: FileStatus.sent,
      ));
      notifyListeners();
    } catch (e) {
      log('File send error: $e');
      messages.add(ChatMessage.text(sender: device.name, isMine: true, text: '[ERROR] $e'));
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    messages.clear();
    final events = await RelayService.query([
      Filter(
        kinds: const [445],
        since: DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch ~/ 1000,
        limit: 50,
      ),
    ]);
    final seen = <String>{};
    for (final raw in events) {
      final tags = raw['tags'] as List? ?? [];
      final hTag = tags.cast<List>().firstWhere((t) => t[0] == 'h', orElse: () => ['h', ''])[1] as String;
      if (hTag.isEmpty || hTag != group.nostrGroupId) continue;
      final eid = raw['id'] as String?;
      if (eid != null && !seen.add(eid)) continue;
      try {
        final m = await device.marmot.processIncoming(jsonEncode(raw));
        if (m == null) continue;
        final mine = m.senderNpub == device.npub;
        final sender = mine ? device.name : m.senderNpub.substring(0, 8);
        final caption = (m.text != null && m.text!.trim().isNotEmpty) ? m.text : null;
        if (m.media.isNotEmpty) {
          for (final ref in m.media) {
            final saved = _downloaded[ref.url];
            messages.add(ChatMessage.file(
              sender: sender,
              isMine: mine,
              media: ref,
              text: caption,
              status: saved != null ? FileStatus.done : FileStatus.pending,
              savedPath: saved,
            ));
          }
        } else {
          messages.add(ChatMessage.text(sender: sender, isMine: mine, text: m.text ?? ''));
        }
      } catch (e) {
        log('  process error: $e');
      }
    }
    await refreshGroup();
    log('${device.name}: refreshed (${events.length} events, ${messages.length} messages)');
    notifyListeners();
  }

  Future<void> downloadFile(ChatMessage m) async {
    final ref = m.media;
    if (ref == null) return;
    m.status = FileStatus.downloading;
    notifyListeners();
    try {
      final encrypted = await BlossomService.download(ref.url);
      if (encrypted == null) {
        m.status = FileStatus.error;
        m.errorMsg = 'Download failed';
        notifyListeners();
        return;
      }
      final input = MediaRefInput(
        url: ref.url,
        originalHash: ref.originalHash,
        mimeType: ref.mimeType,
        filename: ref.filename,
        schemeVersion: ref.schemeVersion,
        nonce: ref.nonce,
      );
      final dec = await device.marmot.decryptMedia(group.id, encrypted, input);

      final dir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${dir.path}/marmot_media');
      if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
      final f = File('${mediaDir.path}/${ref.filename}');
      await f.writeAsBytes(dec);

      _downloaded[ref.url] = f.path;
      m.status = FileStatus.done;
      m.savedPath = f.path;
      log('${device.name}: saved ${ref.filename} (${dec.length}B)');
      notifyListeners();
    } catch (e) {
      log('Download error: $e');
      m.status = FileStatus.error;
      m.errorMsg = '$e';
      notifyListeners();
    }
  }

  String _mimeType(String ext) {
    const map = {
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png',
      'gif': 'image/gif', 'webp': 'image/webp', 'mp4': 'video/mp4',
      'txt': 'text/plain', 'pdf': 'application/pdf', 'json': 'application/json',
      'bin': 'application/octet-stream',
    };
    return map[ext.toLowerCase()] ?? 'application/octet-stream';
  }
}
