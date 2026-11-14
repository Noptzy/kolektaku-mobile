import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/features/dev/gate/gate_runner.dart';
import 'package:kolektaku/features/dev/gate/gate_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

GateStep passing(String name) => GateStep(name, () async => 'ok $name');

GateStep failing(String name) =>
    GateStep(name, () async => throw StateError('boom'));

void main() {
  group('runGate', () {
    test('runs every step in order and keeps going after a failure', () async {
      final started = <String>[];
      final outcomes = await runGate([
        passing('a'),
        failing('b'),
        passing('c'),
      ], onStart: (step) => started.add(step.name));
      expect(started, ['a', 'b', 'c']);
      expect(outcomes.map((o) => o.passed), [true, false, true]);
      expect(outcomes[1].detail, contains('boom'));
      expect(allPassed(outcomes), isFalse);
    });

    test('a step that never finishes is failed by the timeout', () async {
      final outcomes = await runGate([
        GateStep('stuck', () => Completer<String>().future),
      ], perStep: const Duration(milliseconds: 50));
      expect(outcomes.single.passed, isFalse);
    });

    test('an empty gate is not a pass', () {
      expect(allPassed(const []), isFalse);
    });

    test('every outcome is announced as it happens', () async {
      final seen = <String>[];
      await runGate([
        passing('a'),
        failing('b'),
      ], onOutcome: (outcome) => seen.add('${outcome.name}:${outcome.passed}'));
      expect(seen, ['a:true', 'b:false']);
    });
  });

  group('GateScreen', () {
    Future<void> show(WidgetTester tester, List<GateStep> steps) async {
      await tester.pumpWidget(
        ShadApp(
          darkTheme: kolektakuDarkTheme(),
          themeMode: ThemeMode.dark,
          home: GateScreen(steps: steps),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('shows every step and a passing verdict', (tester) async {
      await show(tester, [passing('satu'), passing('dua')]);
      expect(find.text('HASIL: LULUS'), findsOneWidget);
      expect(find.textContaining('LULUS  satu'), findsOneWidget);
      expect(find.textContaining('LULUS  dua'), findsOneWidget);
    });

    testWidgets('one failing step makes the whole gate fail', (tester) async {
      await show(tester, [passing('satu'), failing('dua')]);
      expect(find.text('HASIL: GAGAL'), findsOneWidget);
      expect(find.textContaining('GAGAL  dua'), findsOneWidget);
      expect(find.textContaining('boom'), findsOneWidget);
    });
  });
}
