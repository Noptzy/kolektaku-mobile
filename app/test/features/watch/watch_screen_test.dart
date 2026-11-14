import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'watch_harness.dart';

Future<void> settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 700));

void main() {
  testWidgets('opens the episode and starts playing from the beginning', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    expect(harness.engine.opened.single.url, 'https://first.test/v-720.mp4');
    expect(harness.engine.startedAt.single, Duration.zero);
    expect(find.byKey(const Key('fake-video')), findsOneWidget);
    expect(find.textContaining('Kimi no Na wa.'), findsWidgets);
    expect(find.textContaining('Ep 1'), findsWidgets);
    expect(find.byKey(const Key('change-server')), findsOneWidget);
    expect(find.textContaining('Sumber:'), findsNothing);
  });

  testWidgets('resumes from the saved position', (tester) async {
    final harness = WatchHarness(resume: const Duration(seconds: 90));
    await harness.open(tester);
    expect(harness.engine.startedAt.single, const Duration(seconds: 90));
  });

  testWidgets('an explicit start time beats the saved position', (
    tester,
  ) async {
    final harness = WatchHarness(
      resume: const Duration(seconds: 90),
      startAt: const Duration(seconds: 276),
    );
    await harness.open(tester);
    expect(harness.engine.startedAt.single, const Duration(seconds: 276));
  });

  testWidgets('double tapping the right half skips forward ten seconds', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    final zone = find.byKey(const Key('zone-forward'));
    await tester.tap(zone);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zone);
    await settle(tester);
    expect(harness.engine.log, contains('seek 10'));
    expect(find.text('+10 dtk'), findsOneWidget);
  });

  testWidgets('double tapping the left half skips back but not below zero', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    final zone = find.byKey(const Key('zone-back'));
    await tester.tap(zone);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(zone);
    await settle(tester);
    expect(harness.engine.log, contains('seek 0'));
  });

  testWidgets('the play button pauses and resumes', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('play-pause')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('play-pause')));
    await tester.pump();
    expect(harness.engine.log, containsAllInOrder(['pause', 'play']));
  });

  testWidgets('the speed menu changes the playback speed', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('player-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-row-speed')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('option-1.5x')));
    await tester.pumpAndSettle();
    expect(harness.engine.log, contains('speed 1.5'));
  });

  testWidgets('the quality menu reopens the stream at the same position', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    harness.engine.emit(position: const Duration(seconds: 120), playing: true);
    await tester.tap(find.byKey(const Key('player-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-row-quality')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('option-480p')));
    await tester.pumpAndSettle();
    expect(harness.engine.opened.last.url, 'https://first.test/v-480.mp4');
    expect(harness.engine.startedAt.last, const Duration(seconds: 120));
  });
}
