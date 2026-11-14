import 'dart:async';

import 'package:flutter/widgets.dart';

class RefreshOnVisible extends StatefulWidget {
  const RefreshOnVisible({
    super.key,
    required this.onVisible,
    required this.child,
  });

  final VoidCallback onVisible;
  final Widget child;

  @override
  State<RefreshOnVisible> createState() => _RefreshOnVisibleState();
}

class _RefreshOnVisibleState extends State<RefreshOnVisible> {
  bool? _wasVisible;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.of(context);
    final before = _wasVisible;
    _wasVisible = visible;
    if (visible && before == false) scheduleMicrotask(widget.onVisible);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
