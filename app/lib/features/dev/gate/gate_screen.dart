import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'gate_runner.dart';
import 'gate_steps.dart';

class GateScreen extends StatefulWidget {
  const GateScreen({super.key, this.steps});

  final List<GateStep>? steps;

  @override
  State<GateScreen> createState() => _GateScreenState();
}

class _GateScreenState extends State<GateScreen> {
  late final List<GateStep> _steps = widget.steps ?? coreGateSteps();
  final List<GateOutcome> _outcomes = [];
  String? _running;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final outcomes = await runGate(
      _steps,
      onStart: (step) {
        if (mounted) setState(() => _running = step.name);
      },
      onOutcome: (outcome) {
        final verdict = outcome.passed ? 'PASS' : 'FAIL';
        debugPrint('GATE $verdict ${outcome.name}: ${outcome.detail}');
        if (mounted) setState(() => _outcomes.add(outcome));
      },
    );
    debugPrint('GATE RESULT ${allPassed(outcomes) ? 'PASS' : 'FAIL'}');
    if (mounted) {
      setState(() {
        _running = null;
        _done = true;
      });
    }
  }

  String get _headline {
    if (!_done) return 'Berjalan: ${_running ?? '...'}';
    return allPassed(_outcomes) ? 'HASIL: LULUS' : 'HASIL: GAGAL';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.background,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Gerbang teknis', style: theme.textTheme.h3),
            const SizedBox(height: 4),
            Text(
              _headline,
              key: const Key('gate-verdict'),
              style: theme.textTheme.large,
            ),
            const SizedBox(height: 16),
            for (final outcome in _outcomes) _row(outcome),
          ],
        ),
      ),
    );
  }

  Widget _row(GateOutcome outcome) {
    final verdict = outcome.passed ? 'LULUS' : 'GAGAL';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ShadCard(
        key: Key('gate-${outcome.name}'),
        title: Text('$verdict  ${outcome.name}'),
        description: Text(
          '${outcome.detail}  (${outcome.elapsed.inMilliseconds} ms)',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
