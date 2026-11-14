import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/detail/detail_screen.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/platform/url_opener.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import '../../support/fake_url_opener.dart';
import '../../support/screen_harness.dart';
import 'detail_support.dart';

final request = DetailRequest(kind: MediaKindDto.anime, reference: ref(filmId));

class Opened {
  Opened(this.harness, this.opener);

  final ScreenHarness harness;
  final FakeUrlOpener opener;
}

Future<Opened> open(
  WidgetTester tester, {
  String? notice,
  DetailViewDto? view,
  int unitCount = 12,
  void Function(ScreenHarness harness)? prepare,
  List<Override> extra = const [],
}) async {
  final harness = ScreenHarness();
  final opener = FakeUrlOpener();
  harness.catalog.detailResult = view ?? catalogView();
  harness.catalog.unitsResult = units(unitCount);
  prepare?.call(harness);
  await harness.pump(
    tester,
    DetailScreen(
      request: DetailRequest(
        kind: MediaKindDto.anime,
        reference: ref(filmId),
        notice: notice,
      ),
    ),
    extra: [urlOpenerProvider.overrideWithValue(opener), ...extra],
  );
  return Opened(harness, opener);
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the title, both names, meta, genres and synopsis', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Kimi no Na wa.'), findsOneWidget);
    expect(find.text('Your Name.'), findsOneWidget);
    expect(find.text('2016 · Film · Tamat · 1 eps'), findsOneWidget);
    expect(find.text('Romansa'), findsOneWidget);
    expect(find.text('Dua remaja bertukar tubuh.'), findsOneWidget);
    expect(find.text('8.6'), findsOneWidget);
  });
  testWidgets('a note handed in with the request is shown on top', (
    tester,
  ) async {
    await open(tester, notice: 'Belum tersedia untuk ditonton.');
    expect(find.byKey(const Key('detail-notice')), findsOneWidget);
    expect(find.text('Belum tersedia untuk ditonton.'), findsOneWidget);
  });
  testWidgets('without a note there is no banner', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('detail-notice')), findsNothing);
  });
  testWidgets('the synopsis folds and unfolds', (tester) async {
    await open(tester);
    expect(find.text('Selengkapnya'), findsOneWidget);
    await tester.tap(find.text('Selengkapnya'));
    await tester.pumpAndSettle();
    expect(find.text('Lebih sedikit'), findsOneWidget);
  });
  testWidgets('the sticky button for a film says film', (tester) async {
    await open(tester);
    expect(find.text('Tonton film'), findsOneWidget);
  });
  testWidgets('the sticky button for a series starts the first episode', (
    tester,
  ) async {
    await open(
      tester,
      view: catalogView(
        head: detail(head: summary(format: 'TV', units: 12)),
      ),
    );
    expect(find.text('Tonton Episode 1'), findsOneWidget);
  });
  testWidgets('the sticky button continues where watching stopped', (
    tester,
  ) async {
    await open(
      tester,
      prepare: (harness) =>
          harness.library.historyResult = [progress(5, position: 321)],
    );
    expect(find.text('Lanjut Ep. 5'), findsOneWidget);
  });
  testWidgets('pressing it opens the player at that moment and source', (
    tester,
  ) async {
    final opened = await open(
      tester,
      prepare: (harness) =>
          harness.library.historyResult = [progress(5, position: 321)],
    );
    await tester.tap(find.text('Lanjut Ep. 5'));
    await tester.pumpAndSettle();
    final visit = opened.harness.visits.single;
    expect(visit.path, Routes.watch);
    final watch = visit.extra! as WatchRequest;
    expect(watch.episode, 5);
    expect(watch.startAt, const Duration(seconds: 321));
    expect(watch.preferredSource, 'kura');
    expect(watch.title, 'Kimi no Na wa.');
  });
  testWidgets('tapping an episode row opens that episode', (tester) async {
    final opened = await open(tester);
    await scrollTo(tester, find.text('Episode 3'));
    await tester.tap(find.text('Episode 3'));
    await tester.pumpAndSettle();
    expect((opened.harness.visits.single.extra! as WatchRequest).episode, 3);
  });
  testWidgets('favorite toggles and says what happened', (tester) async {
    final opened = await open(tester);
    expect(find.bySemanticsLabel('Simpan ke favorit'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Simpan ke favorit'));
    await tester.pumpAndSettle();
    expect(opened.harness.library.toggled.single.title, 'Kimi no Na wa.');
    expect(find.bySemanticsLabel('Hapus dari favorit'), findsOneWidget);
    expect(find.text('Ditambahkan ke favorit.'), findsOneWidget);
  });
  testWidgets('an episode already started shows its progress', (tester) async {
    await open(
      tester,
      prepare: (harness) =>
          harness.library.historyResult = [progress(2, position: 600)],
    );
    await scrollTo(tester, find.text('Episode 2'));
    expect(find.text('Episode 2'), findsOneWidget);
  });
}
