import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/year_filter.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/genre/genre_list_screen.dart';
import 'package:kolektaku/features/genre/genre_titles_screen.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/src/rust/error.dart';

import '../../support/screen_harness.dart';
import '../search/search_support.dart';

const action = GenreDto(slug: 'action', name: 'Action');
const comedy = GenreDto(slug: 'comedy', name: 'Comedy');

void main() {
  group('GenreListScreen', () {
    testWidgets('lists every genre in Indonesian', (tester) async {
      final harness = ScreenHarness();
      harness.catalog.genreResult = const [action, comedy];
      await harness.pump(
        tester,
        const GenreListScreen(kind: MediaKindDto.anime),
      );
      expect(find.text('Genre'), findsOneWidget);
      expect(find.text('Aksi'), findsOneWidget);
      expect(find.text('Komedi'), findsOneWidget);
    });

    testWidgets('tapping a genre opens its list', (tester) async {
      final harness = ScreenHarness();
      harness.catalog.genreResult = const [action];
      await harness.pump(
        tester,
        const GenreListScreen(kind: MediaKindDto.anime),
      );
      await tester.tap(find.text('Aksi'));
      await tester.pumpAndSettle();
      final visit = harness.visits.single;
      expect(visit.path, Routes.genre);
      final args = visit.extra! as GenreRouteArgs;
      expect(args.kind, MediaKindDto.anime);
      expect(args.genre.slug, 'action');
    });

    testWidgets('no genres shows an empty state', (tester) async {
      final harness = ScreenHarness();
      await harness.pump(
        tester,
        const GenreListScreen(kind: MediaKindDto.manga),
      );
      expect(find.text('Belum ada genre'), findsOneWidget);
    });
  });

  group('GenreTitlesScreen', () {
    Future<ScreenHarness> open(
      WidgetTester tester, {
      void Function(ScreenHarness harness)? prepare,
    }) async {
      final harness = ScreenHarness();
      prepare?.call(harness);
      await harness.pump(
        tester,
        const GenreTitlesScreen(kind: MediaKindDto.anime, genre: action),
      );
      return harness;
    }

    testWidgets('shows the genre name and its titles', (tester) async {
      final harness = await open(
        tester,
        prepare: (harness) =>
            harness.catalog.searchResult = page([card(1, title: 'Petarung')]),
      );
      expect(find.text('Aksi'), findsOneWidget);
      expect(find.text('Petarung'), findsOneWidget);
      expect(harness.catalog.genrePages, ['anime|action|1|newest']);
    });

    testWidgets('the filter sheet reloads in that order', (tester) async {
      final harness = await open(
        tester,
        prepare: (harness) =>
            harness.catalog.searchResult = page([card(1, title: 'Petarung')]),
      );
      await tester.tap(find.byKey(const Key('open-filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('order-az')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-apply')));
      await tester.pumpAndSettle();
      expect(harness.catalog.genrePages.last, 'anime|action|1|az');
      expect(find.byKey(const Key('active-A-Z')), findsOneWidget);
    });

    testWidgets('a year shows what the catalog answers for that year', (
      tester,
    ) async {
      final year = DateTime.now().year;
      final harness = await open(
        tester,
        prepare: (harness) {
          harness.catalog.searchResult = page([card(1, title: 'Biasa')]);
          harness.catalog.discoverResult = page([
            card(2, title: 'Tahun Itu', year: year),
          ]);
        },
      );
      await tester.tap(find.byKey(const Key('open-filters')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(Key('year-$year')));
      await tester.tap(find.byKey(Key('year-$year')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-apply')));
      await tester.pumpAndSettle();
      expect(find.text('Tahun Itu'), findsOneWidget);
      expect(find.text('Biasa'), findsNothing);
      final ask = harness.catalog.discoverAsks.single;
      expect(ask['genre'], 'Action');
      expect(ask['year'], YearFilter.only(year));
      expect(find.byKey(Key('active-$year')), findsOneWidget);
    });

    testWidgets('a year that has nothing in this genre says so', (
      tester,
    ) async {
      await open(
        tester,
        prepare: (harness) =>
            harness.catalog.searchResult = page([card(1, title: 'Biasa')]),
      );
      final year = DateTime.now().year;
      await tester.tap(find.byKey(const Key('open-filters')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(Key('year-$year')));
      await tester.tap(find.byKey(Key('year-$year')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-apply')));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada judul'), findsOneWidget);
    });

    testWidgets('the next page loads by itself near the end', (tester) async {
      await open(
        tester,
        prepare: (harness) =>
            harness.catalog.onGenre = (kind, slug, number, order) async =>
                number == 1
                ? page([card(1, title: 'Satu')], hasNext: true)
                : page([card(2, title: 'Dua')]),
      );
      expect(find.text('Dua'), findsOneWidget);
      expect(find.byKey(const Key('load-more')), findsNothing);
    });

    testWidgets('opening a title goes to its detail', (tester) async {
      final harness = await open(
        tester,
        prepare: (harness) =>
            harness.catalog.searchResult = page([card(5, title: 'Pilihan')]),
      );
      await tester.tap(find.text('Pilihan'));
      await tester.pumpAndSettle();
      final visit = harness.visits.single;
      expect(visit.path, Routes.detail);
      expect((visit.extra! as DetailRequest).reference, card(5).reference);
    });

    testWidgets('an empty genre says so', (tester) async {
      await open(tester);
      expect(find.text('Belum ada judul'), findsOneWidget);
    });

    testWidgets('a failure shows its message with retry', (tester) async {
      final harness = await open(
        tester,
        prepare: (harness) =>
            harness.catalog.onGenre = (kind, slug, number, order) async =>
                throw BridgeError(kind: BridgeErrorKind.network, detail: 'x'),
      );
      expect(find.text('Tidak ada koneksi'), findsOneWidget);
      harness.catalog.onGenre = null;
      harness.catalog.searchResult = page([card(1, title: 'Pulih')]);
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Pulih'), findsOneWidget);
    });
  });
}
