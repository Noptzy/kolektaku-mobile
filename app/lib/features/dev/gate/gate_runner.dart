typedef GateAction = Future<String> Function();

class GateStep {
  const GateStep(this.name, this.action);

  final String name;
  final GateAction action;
}

class GateOutcome {
  const GateOutcome({
    required this.name,
    required this.passed,
    required this.detail,
    required this.elapsed,
  });

  final String name;
  final bool passed;
  final String detail;
  final Duration elapsed;
}

Future<List<GateOutcome>> runGate(
  List<GateStep> steps, {
  void Function(GateStep step)? onStart,
  void Function(GateOutcome outcome)? onOutcome,
  Duration perStep = const Duration(minutes: 3),
}) async {
  final outcomes = <GateOutcome>[];
  for (final step in steps) {
    onStart?.call(step);
    final clock = Stopwatch()..start();
    GateOutcome outcome;
    try {
      final detail = await step.action().timeout(perStep);
      outcome = GateOutcome(
        name: step.name,
        passed: true,
        detail: detail,
        elapsed: clock.elapsed,
      );
    } on Object catch (error) {
      outcome = GateOutcome(
        name: step.name,
        passed: false,
        detail: error.toString(),
        elapsed: clock.elapsed,
      );
    }
    outcomes.add(outcome);
    onOutcome?.call(outcome);
  }
  return outcomes;
}

bool allPassed(List<GateOutcome> outcomes) =>
    outcomes.isNotEmpty && outcomes.every((outcome) => outcome.passed);
