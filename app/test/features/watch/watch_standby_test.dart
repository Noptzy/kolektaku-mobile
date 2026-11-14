import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/standby_panel.dart';
import 'package:kolektaku/features/watch/player/stream_spinner.dart';
import 'package:kolektaku/src/rust/dto/episodes.dart';

import 'watch_harness.dart';

Future<void> opening(WidgetTester tester, WatchHarness harness) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(harness.app());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('the player shows a spinner while the stream is prepared', (
    tester,
  ) async {
    final hold = Completer<void>();
    await opening(tester, WatchHarness(hold: hold));
    expect(find.text('Menyiapkan video…'), findsOneWidget);
    expect(find.byType(StreamSpinner), findsOneWidget);
    expect(find.byKey(const Key('back')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(StandbyPanel),
        matching: find.textContaining('Kimi no Na wa.'),
      ),
      findsOneWidget,
    );
    hold.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Menyiapkan video…'), findsNothing);
    expect(find.byType(StreamSpinner), findsNothing);
  });

  testWidgets('the episode list is already there before the stream is', (
    tester,
  ) async {
    final hold = Completer<void>();
    await opening(tester, WatchHarness(hold: hold, unitCount: 8));
    expect(find.text('Menyiapkan video…'), findsOneWidget);
    expect(find.text('Semua episode'), findsOneWidget);
    expect(find.text('Episode 2'), findsWidgets);
    expect(find.text('Selanjutnya'), findsOneWidget);
    hold.complete();
    await tester.pump();
  });

  testWidgets('only the server button waits for the stream', (tester) async {
    final hold = Completer<void>();
    await opening(tester, WatchHarness(hold: hold, unitCount: 8));
    expect(find.byKey(const Key('previous-episode')), findsOneWidget);
    expect(find.byKey(const Key('next-episode')), findsOneWidget);
    expect(find.byKey(const Key('change-server')), findsOneWidget);
    hold.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('change-server')), findsOneWidget);
  });

  testWidgets('the episode picture sits behind the spinner', (tester) async {
    final hold = Completer<void>();
    final harness = WatchHarness(
      hold: hold,
      infos: {
        1: const EpisodeInfoDto(
          number: 1,
          title: 'Awal',
          thumbnailUrl: 'https://example.invalid/ep1.jpg',
        ),
      },
    );
    await opening(tester, harness);
    expect(find.byKey(const Key('standby-backdrop')), findsOneWidget);
    hold.complete();
    await tester.pump();
  });

  testWidgets('without a picture the panel stays plain', (tester) async {
    final hold = Completer<void>();
    await opening(tester, WatchHarness(hold: hold));
    expect(find.byKey(const Key('standby-backdrop')), findsNothing);
    hold.complete();
    await tester.pump();
  });

  testWidgets('a slow load says so after ten seconds', (tester) async {
    final hold = Completer<void>();
    await opening(tester, WatchHarness(hold: hold));
    double hint() => tester
        .widget<AnimatedOpacity>(
          find.ancestor(
            of: find.byKey(const Key('slow-hint')),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;
    expect(hint(), 0);
    await tester.pump(slowAfter);
    await tester.pump(const Duration(milliseconds: 400));
    expect(hint(), 1);
    hold.complete();
    await tester.pump();
  });

  testWidgets('a failed load keeps the picture and offers a retry', (
    tester,
  ) async {
    final harness = WatchHarness(failToLoad: true);
    await opening(tester, harness);
    expect(find.text('Episode tidak bisa dibuka'), findsOneWidget);
    expect(find.byKey(const Key('retry')), findsOneWidget);
    expect(find.byType(StreamSpinner), findsNothing);
    expect(find.text('Semua episode'), findsOneWidget);
  });

  testWidgets('reduced motion keeps the spinner still', (tester) async {
    final hold = Completer<void>();
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await opening(tester, WatchHarness(hold: hold));
    expect(find.byType(StreamSpinner), findsOneWidget);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    hold.complete();
    await tester.pump();
  });
}
