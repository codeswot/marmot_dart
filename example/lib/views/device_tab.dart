import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/provider.dart';
import '../viewmodels/device_viewmodel.dart';
import 'group_card.dart';

class DeviceTab extends StatelessWidget {
  const DeviceTab({super.key});

  @override
  Widget build(BuildContext c) {
    final vm = ChangeNotifierProvider.of<DeviceViewModel>(c);
    return _DeviceView(vm: vm);
  }
}

class _DeviceView extends StatefulWidget {
  final DeviceViewModel vm;
  const _DeviceView({required this.vm});

  @override
  State<_DeviceView> createState() => _DeviceViewState();
}

class _DeviceViewState extends State<_DeviceView> {
  DeviceViewModel get vm => widget.vm;
  final _nameCtrl = TextEditingController();
  final _npubsCtrl = TextEditingController();
  final _nsecCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    vm.addListener(() => setState(() {}));
    vm.reloadGroups();
  }

  @override
  void dispose() {
    vm.removeListener(() {});
    _nameCtrl.dispose();
    _npubsCtrl.dispose();
    _nsecCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => ListView(
    controller: _scrollCtrl,
    padding: const EdgeInsets.all(16),
    children: [
      // Identity card
      if (vm.hasIdentity)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vm.name, style: Theme.of(c).textTheme.titleSmall),
                _copyRow(c, 'npub', vm.npub),
                _copyRow(c, 'nsec', vm.nsec),
                _copyRow(c, 'hex', vm.hex),
              ],
            ),
          ),
        )
      else
        Card(
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No identity'),
          ),
        ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: vm.generate,
              icon: const Icon(Icons.add),
              label: const Text('Gen'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.icon(
              onPressed: vm.publishKeyPackage,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Pub KP'),
            ),
          ),
        ],
      ),
      TextField(
        controller: _nsecCtrl,
        decoration: const InputDecoration(
          labelText: 'Import nsec',
          border: OutlineInputBorder(),
        ),
      ),
      OutlinedButton(
        onPressed: () async {
          await vm.importNsec(_nsecCtrl.text);
          _nsecCtrl.clear();
        },
        child: const Text('Import'),
      ),

      // Create group
      if (vm.hasIdentity) ...[
        const SizedBox(height: 16),
        Text('Create group', style: Theme.of(c).textTheme.titleMedium),
        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Group name',
            border: OutlineInputBorder(),
          ),
        ),
        TextField(
          controller: _npubsCtrl,
          decoration: const InputDecoration(
            labelText: 'Member npubs (comma-sep)',
            border: OutlineInputBorder(),
          ),
        ),
        FilledButton.icon(
          onPressed: () async {
            final np = _npubsCtrl.text
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            final name = _nameCtrl.text.trim().isEmpty
                ? '${vm.name} ${DateTime.now().millisecond}'
                : _nameCtrl.text.trim();
            await vm.doCreateGroup(name, np);
            _nameCtrl.clear();
            _npubsCtrl.clear();
            _scrollCtrl.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
          icon: const Icon(Icons.group_add),
          label: const Text('Create group'),
        ),
        if (vm.lastWelcome != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  vm.lastWelcome!,
                  style: Theme.of(c).textTheme.bodySmall,
                  maxLines: 2,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: vm.lastWelcome!)),
              ),
            ],
          ),
        ],
      ],

      // Groups
      if (vm.groups.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(
          'Groups (${vm.groups.length})',
          style: Theme.of(c).textTheme.titleMedium,
        ),
        ...vm.groups.map((g) => GroupCard(vm.device, g)),
      ],

      // Welcome fetch/join
      const SizedBox(height: 16),
      Row(
        children: [
          Text('Join group', style: Theme.of(c).textTheme.titleMedium),
          const Spacer(),
          FilledButton.tonalIcon(
            onPressed: vm.fetchWelcomes,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Fetch welcomes'),
          ),
        ],
      ),
      ...vm.fetchedWelcomes.map(
        (w) => Card(
          child: ListTile(
            title: Text(
              'Welcome ${w['id']!.substring(0, 12)}...',
              style: Theme.of(c).textTheme.bodySmall,
            ),
            trailing: FilledButton.tonal(
              onPressed: () => vm.joinWelcome(w['id']!, w['rumor']!),
              child: const Text('Join'),
            ),
          ),
        ),
      ),

      if (vm.status.isNotEmpty)
        Padding(padding: const EdgeInsets.only(top: 8), child: Text(vm.status)),
    ],
  );

  Widget _copyRow(BuildContext c, String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            l,
            style: Theme.of(
              c,
            ).textTheme.labelSmall?.copyWith(color: Colors.grey),
          ),
        ),
        Expanded(
          child: SelectableText(v, style: Theme.of(c).textTheme.bodySmall),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 16),
          visualDensity: VisualDensity.compact,
          onPressed: () => Clipboard.setData(ClipboardData(text: v)),
        ),
      ],
    ),
  );
}
