import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/collection/history_box.dart';
import 'package:kolektaku/features/collection/history_row.dart';
import 'package:kolektaku/features/reader/read_request.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../detail/detail_support.dart' show ref;

import 'collection_support.dart';

void main() {
  testWidgets('a history row plays that episode where it was left', (
    tester,
  ) async {
    final harness = await open(tester, history: [progress(5, title: 'Buka')]);
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    final visit = harness.visits.single;
    expect(visit.path, Routes.watch);
    final request = visit.extra! as WatchRequest;
    expect(request.reference, ref(5));
    expect(request.episode, 2);
    expect(request.startAt, const Duration(seconds: 600));
  });

  testWidgets('a finished history row replays from the start', (tester) async {
    final harness = await open(
      tester,
      history: [progress(5, title: 'Tamat', completed: true)],
    );
    await tester.tap(find.text('Tamat'));
    await tester.pumpAndSettle();
    expect((harness.visits.single.extra! as WatchRequest).startAt, isNull);
  });

  testWidgets('a comic history row reads that chapter', (tester) async {
    final harness = await open(
      tester,
      history: [
        progress(8, kind: MediaKindDto.manga, title: 'Bacaan', unit: 7),
      ],
    );
    await tester.tap(find.byKey(const Key('kind-manga')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bacaan'));
    await tester.pumpAndSettle();
    final visit = harness.visits.single;
    expect(visit.path, Routes.read);
    expect((visit.extra! as ReadRequest).chapter, 7);
  });

  testWidgets('a long history scrolls inside its own box', (tester) async {
    await open(
      tester,
      history: [for (var i = 1; i <= 12; i++) progress(i, title: 'Judul $i')],
    );
    final box = tester.getSize(find.byKey(const Key('history-box')));
    expect(box.height, historyVisibleRows * historyRowHeight);
    expect(find.text('Judul 12'), findsNothing);
  });

  testWidgets('a short history needs no inner scrolling', (tester) async {
    await open(
      tester,
      history: [for (var i = 1; i <= 3; i++) progress(i, title: 'Judul $i')],
    );
    final box = tester.getSize(find.byKey(const Key('history-box')));
    expect(box.height, 3 * historyRowHeight);
  });

  testWidgets('the settings button moves to the settings tab', (tester) async {
    final harness = await open(tester);
    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pumpAndSettle();
    expect(harness.visits.single.path, Routes.settings);
  });

  testWidgets('the kind switch is one full width box with both kinds', (
    tester,
  ) async {
    await open(tester);
    final anime = tester.getSize(find.byKey(const Key('kind-anime')));
    final comic = tester.getSize(find.byKey(const Key('kind-manga')));
    expect(anime.width, comic.width);
    expect(find.text('Anime'), findsWidgets);
    expect(find.text('Komik'), findsWidgets);
  });
}
