import 'package:flutter/material.dart';

import '../main.dart' show alice, bob, logs;

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext c) => ListView(padding: const EdgeInsets.all(16), children: [
    OutlinedButton.icon(
      onPressed: () {
        alice.dispose(); bob.dispose(); logs.clear();
        ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text('Sessions cleared. Restart app.')));
      },
      icon: const Icon(Icons.delete_sweep),
      label: const Text('Clear all sessions'),
    ),
    const SizedBox(height: 16),
    const Text('Logs', style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    ...logs.map((l) => Text(l, style: Theme.of(c).textTheme.bodySmall)),
  ]);
}
