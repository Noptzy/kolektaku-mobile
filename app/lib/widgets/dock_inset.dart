import 'package:flutter/widgets.dart';

class DockInset extends InheritedWidget {
  const DockInset({super.key, required this.clearance, required super.child});

  final double clearance;

  static double of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DockInset>();
    return scope?.clearance ?? 0;
  }

  @override
  bool updateShouldNotify(DockInset oldWidget) =>
      clearance != oldWidget.clearance;
}

class DockSpace extends StatelessWidget {
  const DockSpace({super.key, this.extra = 0});

  final double extra;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: DockInset.of(context) + extra);
  }
}
