import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/episode_row.dart';
import 'package:kolektaku/features/watch/episodes_sheet.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'watch_harness.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('helpers', () {
    test('the tag names the unit by kind', () {
      expect(episodeTag(MediaKindDto.anime, 1086), 'Ep 1086');
      expect(episodeTag(MediaKindDto.manga, 12), 'Ch 12');
      expect(episodeTag(MediaKindDto.anime, 6.5), 'Ep 6.5');
    });

    test('the sheet opens one row above the current episode', () {
      expect(sheetOffsetFor(0), 0);
      expect(sheetOffsetFor(1), 0);
      expect(sheetOffsetFor(10), 9 * episodeRowHeight);
    });
  });

  test('the sheet list fills the screen but never gets tiny', () {
    expect(sheetListHeight(634), 504);
    expect(sheetListHeight(1280), 1150);
    expect(sheetListHeight(200), 200);
  });

  testWidgets('in portrait the list below replaces the episodes button', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    expect(find.byKey(const Key('episodes')), findsNothing);
    expect(find.text('Semua episode'), findsOneWidget);
  });

  testWidgets('fullscreen brings the episodes button back', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('fullscreen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('episodes')), findsOneWidget);
  });

  testWidgets('the episodes button lists every episode in a sheet', (
    tester,
  ) async {
    final harness = WatchHarness(unitCount: 8);
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('fullscreen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('episodes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('episodes-list')), findsOneWidget);
    expect(find.text('Episode 3'), findsWidgets);
  });

  testWidgets('picking an episode closes the sheet and opens it', (
    tester,
  ) async {
    final harness = WatchHarness(unitCount: 8);
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('fullscreen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('episodes')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('episodes-list')),
        matching: find.text('Episode 4'),
      ),
    );
    await settle(tester);
    expect(harness.openedEpisodes.last, 4);
    expect(find.byKey(const Key('episodes-list')), findsNothing);
  });

  testWidgets('the same button works in fullscreen', (tester) async {
    final harness = WatchHarness(unitCount: 8);
    await harness.open(tester);
    await tester.tap(find.byKey(const Key('fullscreen')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('change-server')), findsNothing);
    await tester.tap(find.byKey(const Key('episodes')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('episodes-list')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('episodes-list')),
        matching: find.text('Episode 4'),
      ),
    );
    await settle(tester);
    expect(harness.openedEpisodes.last, 4);
    expect(harness.fullscreen.log.last, 'enter');
  });

  testWidgets('without an episode list there is no button', (tester) async {
    final harness = WatchHarness(unitCount: 0);
    await harness.open(tester);
    expect(find.byKey(const Key('episodes')), findsNothing);
  });
}
