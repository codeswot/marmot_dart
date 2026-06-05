import 'package:flutter/material.dart';

import 'models/device.dart';
import 'viewmodels/device_viewmodel.dart';
import 'widgets/provider.dart';
import 'views/device_tab.dart';
import 'views/settings_tab.dart';

final logs = <String>[];
void log(String msg) {
  final ts = DateTime.now().toIso8601String().substring(11, 23);
  final line = '[$ts] $msg';
  debugPrint(line);
  logs.add(line);
}

final alice = Device('Alice');
final bob = Device('Bob');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  log('Starting...');
  await alice.init();
  await bob.init();
  log('Both devices ready');
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    title: 'marmot_dart',
    theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
    home: const HomePage(),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tab = 0;

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: const Text('marmot_dart')),
    body: IndexedStack(
      index: _tab,
      children: [
        ChangeNotifierProvider(
          create: (_) => DeviceViewModel(alice),
          child: const DeviceTab(),
        ),
        ChangeNotifierProvider(
          create: (_) => DeviceViewModel(bob),
          child: const DeviceTab(),
        ),
        const SettingsTab(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (i) => setState(() => _tab = i),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.person, color: Colors.pink),
          label: 'Alice',
        ),
        NavigationDestination(
          icon: Icon(Icons.person, color: Colors.blue),
          label: 'Bob',
        ),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    ),
  );
}
