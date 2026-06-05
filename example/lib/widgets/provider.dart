import 'package:flutter/material.dart';

class ChangeNotifierProvider<T extends ChangeNotifier> extends StatefulWidget {
  final T Function(BuildContext) create;
  final Widget child;
  const ChangeNotifierProvider({
    super.key,
    required this.create,
    required this.child,
  });

  @override
  State<ChangeNotifierProvider<T>> createState() =>
      _ChangeNotifierProviderState<T>();

  static T of<T extends ChangeNotifier>(BuildContext context) {
    final s = context
        .findAncestorStateOfType<_ChangeNotifierProviderState<T>>();
    return s!.notifier;
  }
}

class _ChangeNotifierProviderState<T extends ChangeNotifier>
    extends State<ChangeNotifierProvider<T>> {
  late final T notifier = widget.create(context);

  @override
  Widget build(BuildContext c) =>
      ListenableBuilder(listenable: notifier, builder: (_, _) => widget.child);

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }
}
