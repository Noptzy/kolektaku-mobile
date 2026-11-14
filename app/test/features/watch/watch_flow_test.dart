import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'watch_harness.dart';

void main() {
  testWidgets('fullscreen hides the details and back leaves fullscreen first', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    expect(find.byKey(const Key('change-server')), findsOneWidget);
    await tester.tap(find.byKey(const Key('fullscreen')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.fullscreen.log, ['enter']);
    expect(find.byKey(const Key('change-server')), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.fullscreen.log, ['enter', 'exit']);
    expect(find.byKey(const Key('change-server')), findsOneWidget);
  });

  testWidgets('leaving the screen saves progress and releases the engine', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    harness.engine.emit(position: const Duration(seconds: 42), playing: true);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(harness.engine.disposed, isTrue);
    expect(harness.progress.saved.last.$1, const Duration(seconds: 42));
  });

  testWidgets('leaving while fullscreen restores the system screen', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('fullscreen')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(harness.fullscreen.log, ['enter', 'exit']);
  });

  testWidgets(
    'an expired link is fetched again once without the viewer noticing',
    (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      harness.engine.emit(
        position: const Duration(seconds: 300),
        playing: true,
      );
      harness.engine.emit(failure: 'http 403');
      await tester.pump();
      await tester.pump();
      expect(harness.resolves, 2);
      expect(harness.engine.opened.last.url, 'https://fresh.test/v-720.mp4');
      expect(harness.engine.startedAt.last, const Duration(seconds: 300));
      expect(find.byKey(const Key('retry')), findsNothing);
    },
  );

  testWidgets('a second failure offers a retry button', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    harness.engine.emit(failure: 'http 403');
    await tester.pump();
    await tester.pump();
    harness.engine.emit(failure: 'http 403 again');
    await tester.pump();
    expect(find.text('Video gagal diputar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry')));
    await tester.pump();
    await tester.pump();
    expect(harness.resolves, 3);
    expect(find.byKey(const Key('retry')), findsNothing);
  });

  testWidgets('an episode that cannot be opened can be retried', (
    tester,
  ) async {
    final harness = WatchHarness(failToLoad: true);
    await harness.open(tester);
    expect(find.text('Episode tidak bisa dibuka'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry')));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.engine.opened, hasLength(1));
    expect(find.text('Episode tidak bisa dibuka'), findsNothing);
  });

  testWidgets('switching to another source is announced', (tester) async {
    final harness = WatchHarness(sourceSwitched: 'kuramanime');
    await harness.open(tester);
    expect(find.byKey(const Key('switched-notice')), findsOneWidget);
    expect(find.text('Diputar dari sumber lain'), findsOneWidget);
  });

  testWidgets('without a switch there is no notice', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    expect(find.byKey(const Key('switched-notice')), findsNothing);
  });
}
