import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/device.dart';
import '../models/chat_message.dart';
import '../viewmodels/group_viewmodel.dart';
import 'package:marmot_dart/marmot_dart.dart';

class GroupCard extends StatefulWidget {
  final Device device;
  final MarmotGroup group;
  const GroupCard(this.device, this.group, {super.key});

  @override
  State<GroupCard> createState() => _GroupCardState();
}

class _GroupCardState extends State<GroupCard> {
  late final GroupViewModel vm;
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    vm = GroupViewModel(widget.device, widget.group)
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    vm.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Widget _renderMsg(BuildContext c, ChatMessage msg) {
    if (!msg.isFile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '[${msg.sender}] ${msg.text ?? ''}',
          style: Theme.of(c).textTheme.bodySmall,
        ),
      );
    }

    final ref = msg.media!;
    final icon = switch (msg.status) {
      FileStatus.done => Icons.check_circle,
      FileStatus.downloading => Icons.downloading,
      FileStatus.error => Icons.error,
      FileStatus.sent => Icons.cloud_done,
      FileStatus.pending => Icons.cloud_download,
    };
    final subtitle = switch (msg.status) {
      FileStatus.done => 'Saved to Documents/marmot_media',
      FileStatus.downloading => 'Downloading…',
      FileStatus.error => msg.errorMsg ?? 'Error',
      FileStatus.sent => '${ref.mimeType} — sent',
      FileStatus.pending => '${ref.mimeType} — tap to download',
    };

    Widget? trailing;
    if (msg.status == FileStatus.pending || msg.status == FileStatus.error) {
      trailing = FilledButton.tonal(
        onPressed: () => vm.downloadFile(msg),
        child: Text(msg.status == FileStatus.error ? 'Retry' : 'Download'),
      );
    } else if (msg.status == FileStatus.downloading) {
      trailing = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (msg.status == FileStatus.done && msg.savedPath != null) {
      trailing = IconButton(
        icon: const Icon(Icons.copy, size: 16),
        tooltip: msg.savedPath,
        onPressed: () => Clipboard.setData(ClipboardData(text: msg.savedPath!)),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        leading: Icon(icon, size: 24),
        title: Text(
          '[${msg.sender}] ${ref.filename}',
          style: Theme.of(c).textTheme.bodySmall,
        ),
        subtitle: Text(
          msg.text != null ? '${msg.text}\n$subtitle' : subtitle,
          style: Theme.of(c).textTheme.labelSmall,
        ),
        isThreeLine: msg.text != null,
        trailing: trailing,
      ),
    );
  }

  Widget _avatar() {
    if (vm.imageBytes != null) {
      return CircleAvatar(
        radius: 18,
        backgroundImage: MemoryImage(vm.imageBytes!),
      );
    }
    return CircleAvatar(
      radius: 18,
      child: Text(vm.name.isNotEmpty ? vm.name[0].toUpperCase() : '?'),
    );
  }

  Future<void> _showEditDialog(BuildContext c) async {
    final nameCtrl = TextEditingController(text: vm.name);
    final descCtrl = TextEditingController(text: vm.description);
    await showDialog<void>(
      context: c,
      builder: (dctx) => AlertDialog(
        title: const Text('Edit group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: vm.busy
                      ? null
                      : () {
                          Navigator.pop(dctx);
                          vm.doSetGroupImage();
                        },
                  icon: const Icon(Icons.image, size: 16),
                  label: const Text('Set image'),
                ),
                if (vm.imageBytes != null)
                  TextButton.icon(
                    onPressed: vm.busy
                        ? null
                        : () {
                            Navigator.pop(dctx);
                            vm.clearGroupImage();
                          },
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Remove'),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dctx);
              vm.editGroup(name: nameCtrl.text, description: descCtrl.text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Card(
    child: ExpansionTile(
      leading: _avatar(),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${vm.name} (${vm.memberCount}m)${vm.messages.isNotEmpty ? " • ${vm.messages.length}" : ""}',
            ),
          ),
          if (vm.busy)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              visualDensity: VisualDensity.compact,
              onPressed: () => _showEditDialog(c),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: vm.refresh,
          ),
        ],
      ),
      subtitle: Text(
        vm.description.isNotEmpty ? vm.description : vm.id.substring(0, 12),
      ),
      onExpansionChanged: (_) => setState(() {}),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _msgCtrl,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (t) {
              vm.doSendMessage(t);
              _msgCtrl.clear();
            },
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                vm.doSendMessage(_msgCtrl.text);
                _msgCtrl.clear();
              },
              icon: const Icon(Icons.send, size: 16),
              label: const Text('Send'),
            ),
            TextButton.icon(
              onPressed: () {
                vm.doSendFile(_msgCtrl.text);
                _msgCtrl.clear();
              },
              icon: const Icon(Icons.attach_file, size: 16),
              label: const Text('File'),
            ),
          ],
        ),
        if (vm.messages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: vm.messages.map((msg) => _renderMsg(c, msg)).toList(),
            ),
          ),
      ],
    ),
  );
}
