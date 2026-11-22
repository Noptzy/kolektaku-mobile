import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

const glassWindowFrames = 90;
const glassRasterLimitMs = 20.0;
const glassBadWindowsToTrip = 2;

double percentile95(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  return sorted[((sorted.length - 1) * 0.95).round()];
}

class GlassBudget extends ChangeNotifier {
  GlassBudget({
    this.windowFrames = glassWindowFrames,
    this.limitMs = glassRasterLimitMs,
    this.badWindowsToTrip = glassBadWindowsToTrip,
  });

  final int windowFrames;
  final double limitMs;
  final int badWindowsToTrip;
  final List<double> _window = [];
  int _badWindows = 0;
  bool _tripped = false;

  bool get tripped => _tripped;

  void record(Iterable<double> rasterMs) {
    if (_tripped) return;
    for (final sample in rasterMs) {
      _window.add(sample);
      if (_window.length < windowFrames) continue;
      _badWindows = percentile95(_window) > limitMs ? _badWindows + 1 : 0;
      _window.clear();
      if (_badWindows >= badWindowsToTrip) {
        _tripped = true;
        notifyListeners();
        return;
      }
    }
  }
}

class GlassBudgetScope extends InheritedNotifier<GlassBudget> {
  const GlassBudgetScope({
    super.key,
    required GlassBudget budget,
    required super.child,
  }) : super(notifier: budget);

  static bool trippedOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<GlassBudgetScope>();
    return scope?.notifier?.tripped ?? false;
  }
}

class GlassBudgetHost extends StatefulWidget {
  const GlassBudgetHost({super.key, required this.child, this.budget});

  final Widget child;
  final GlassBudget? budget;

  @override
  State<GlassBudgetHost> createState() => _GlassBudgetHostState();
}

class _GlassBudgetHostState extends State<GlassBudgetHost> {
  late final GlassBudget _budget = widget.budget ?? GlassBudget();

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    if (widget.budget == null) _budget.dispose();
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    _budget.record(
      timings.map((timing) => timing.rasterDuration.inMicroseconds / 1000),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassBudgetScope(budget: _budget, child: widget.child);
  }
}
