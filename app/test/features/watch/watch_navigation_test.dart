import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:kolektaku/features/watch/watch_request.dart';

import 'watch_harness.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

bool enabled(WidgetTester tester, String key) =>
    tester
        .widget<ShadButton>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(ShadButton),
          ),
        )
        .onPressed !=
    null;

void main() {
  testWidgets('no site or server name is ever shown', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    expect(find.textContaining('Sumber:'), findsNothing);
    expect(find.textContaining('Srv'), findsNothing);
    expect(find.textContaining('Kurama'), findsNothing);
  });

  testWidgets('the player bar names the title and the episode', (tester) async {
    final harness = WatchHarness(episode: 5);
    await harness.open(tester);
    expect(find.textContaining('Kimi no Na wa.'), findsWidgets);
    expect(find.textContaining('Ep 5'), findsWidgets);
  });

  testWidgets('the first episode has no previous but has a next', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    expect(enabled(tester, 'previous-episode'), isFalse);
    expect(enabled(tester, 'next-episode'), isTrue);
  });

  testWidgets('the last episode has no next', (tester) async {
    final harness = WatchHarness(episode: 12);
    await harness.open(tester);
    expect(enabled(tester, 'previous-episode'), isTrue);
    expect(enabled(tester, 'next-episode'), isFalse);
  });

  testWidgets('next opens the following episode', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('next-episode')));
    await settle(tester);
    expect(harness.openedEpisodes, [1, 2]);
    expect(find.textContaining('Ep 2'), findsWidgets);
  });

  testWidgets('previous opens the episode before', (tester) async {
    final harness = WatchHarness(episode: 5);
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('previous-episode')));
    await settle(tester);
    expect(harness.openedEpisodes, [5, 4]);
  });

  testWidgets('the episode list opens any episode on tap', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.scrollUntilVisible(
      find.text('Episode 7'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(find.text('Episode 7'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Episode 7'));
    await settle(tester);
    expect(harness.openedEpisodes.last, 7);
  });

  testWidgets('change server opens a sheet of numbered servers', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('change-server')));
    await tester.pumpAndSettle();
    expect(find.text('Ganti server'), findsWidgets);
    expect(find.text('Server 1'), findsOneWidget);
    expect(find.text('Server 2'), findsOneWidget);
    expect(find.textContaining('Srv'), findsNothing);
  });

  testWidgets('picking a server reopens the video on it', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('change-server')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('server-option-srv2')));
    await settle(tester);
    expect(harness.resolvedServers.last, 'srv2');
  });

  testWidgets('the sheet can also try another source', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('change-server')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('other-source-option')));
    await settle(tester);
    expect(harness.excluded.last, ['a']);
  });

  testWidgets('an automatic source switch is announced without any names', (
    tester,
  ) async {
    final harness = WatchHarness(sourceSwitched: 'a');
    await harness.open(tester);
    expect(find.text('Diputar dari sumber lain.'), findsOneWidget);
    expect(find.byKey(const Key('switched-notice')), findsOneWidget);
    expect(find.text('Sumber sebelumnya sedang bermasalah.'), findsOneWidget);
  });

  testWidgets('no switch means no notice', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    expect(find.text('Diputar dari sumber lain.'), findsNothing);
    expect(find.byKey(const Key('switched-notice')), findsNothing);
  });

  group('scene estimate', () {
    const estimate = SceneEstimate(
      at: Duration(seconds: 279),
      sourceLength: Duration(seconds: 1418),
    );

    testWidgets('a picture search result shows the estimate bar', (
      tester,
    ) async {
      final harness = WatchHarness(scene: estimate);
      await harness.open(tester);
      expect(find.text('Perkiraan posisi'), findsOneWidget);
      expect(find.byKey(const Key('estimate-back')), findsOneWidget);
    });

    testWidgets('a normal episode has no estimate bar', (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      expect(find.text('Perkiraan posisi'), findsNothing);
    });

    testWidgets('moving to another episode drops the estimate', (tester) async {
      final harness = WatchHarness(scene: estimate);
      await harness.open(tester);
      await tester.tap(find.byKey(const Key('next-episode')));
      await settle(tester);
      expect(find.text('Perkiraan posisi'), findsNothing);
    });
  });

  group('auto continue banner', () {
    testWidgets('appears at the end with the countdown', (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      expect(find.byKey(const Key('auto-next')), findsNothing);
      harness.engine.emit(position: harness.engine.length, playing: false);
      await tester.pump();
      expect(find.byKey(const Key('auto-next')), findsOneWidget);
      expect(find.text('Episode berikutnya dalam 5 dtk'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Episode berikutnya dalam 3 dtk'), findsOneWidget);
    });

    testWidgets('plays the next episode when the time is up', (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      harness.engine.emit(position: harness.engine.length, playing: false);
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      expect(harness.openedEpisodes, [1, 2]);
      expect(find.byKey(const Key('auto-next')), findsNothing);
    });

    testWidgets('cancel keeps the finished episode', (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      harness.engine.emit(position: harness.engine.length, playing: false);
      await tester.pump();
      await tester.tap(find.byKey(const Key('auto-next-cancel')));
      await tester.pump(const Duration(seconds: 10));
      expect(harness.openedEpisodes, [1]);
      expect(find.byKey(const Key('auto-next')), findsNothing);
    });

    testWidgets('play now does not wait', (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      harness.engine.emit(position: harness.engine.length, playing: false);
      await tester.pump();
      await tester.tap(find.byKey(const Key('auto-next-now')));
      await settle(tester);
      expect(harness.openedEpisodes, [1, 2]);
    });

    testWidgets('never shows on the last episode', (tester) async {
      final harness = WatchHarness(episode: 12);
      await harness.open(tester);
      harness.engine.emit(position: harness.engine.length, playing: false);
      await tester.pump();
      expect(find.byKey(const Key('auto-next')), findsNothing);
    });
  });
}
