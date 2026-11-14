import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/search/search_tab_screen.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/error.dart';

import '../../support/screen_harness.dart';
import 'search_support.dart';

Future<ScreenHarness> open(
  WidgetTester tester, {
  void Function(ScreenHarness harness)? prepare,
}) async {
  final harness = ScreenHarness();
  prepare?.call(harness);
  await harness.pump(tester, const SearchTabScreen());
  return harness;
}

Future<void> type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<void> chooseFilter(WidgetTester tester, List<String> keys) async {
  await tester.tap(find.byKey(const Key('open-filters')));
  await tester.pumpAndSettle();
  for (final key in keys) {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const Key('filter-apply')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an empty screen shows past searches and suggestions', (
    tester,
  ) async {
    await open(
      tester,
      prepare: (harness) {
        harness.library.searchHistory = ['kimi no nawa', 'frieren'];
        harness.catalog.homeResult = HomeDto(
          sections: [
            HomeSectionDto(
              id: 'trending',
              cards: [card(1, title: 'Judul Populer')],
            ),
          ],
          notices: const [],
        );
      },
    );
    expect(find.text('Pencarian terakhir'), findsOneWidget);
    expect(find.text('kimi no nawa'), findsOneWidget);
    expect(find.text('Coba cari'), findsOneWidget);
    expect(find.text('Judul Populer'), findsOneWidget);
  });
  testWidgets('with nothing to show there is a plain hint', (tester) async {
    await open(tester);
    expect(find.text('Ketik judul untuk mulai mencari.'), findsOneWidget);
  });
  testWidgets('tapping a past search fills the box and searches', (
    tester,
  ) async {
    final harness = await open(
      tester,
      prepare: (harness) {
        harness.library.searchHistory = ['frieren'];
        harness.catalog.searchResult = page([
          card(1, title: 'Sousou no Frieren'),
        ]);
      },
    );
    await tester.tap(find.text('frieren'));
    await tester.pumpAndSettle();
    expect(harness.catalog.searches, ['anime|frieren|1']);
    expect(find.text('Sousou no Frieren'), findsOneWidget);
  });
  testWidgets('clear all empties the past searches', (tester) async {
    final harness = await open(
      tester,
      prepare: (harness) => harness.library.searchHistory = ['frieren'],
    );
    await tester.tap(find.text('Hapus semua'));
    await tester.pumpAndSettle();
    expect(harness.library.searchHistory, isEmpty);
    expect(find.text('frieren'), findsNothing);
  });
  testWidgets('typing a misspelled title lists the right film', (tester) async {
    final harness = await open(
      tester,
      prepare: (harness) => harness.catalog.searchResult = page([
        card(21519, title: 'Kimi no Na wa.', format: 'MOVIE'),
      ]),
    );
    await type(tester, 'kimi no nawa');
    expect(harness.catalog.searches, ['anime|kimi no nawa|1']);
    expect(find.text('Kimi no Na wa.'), findsOneWidget);
  });
  testWidgets('no results shows a clear message with the query', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'zzzz');
    expect(find.text('Tidak ada hasil'), findsOneWidget);
    expect(find.textContaining('"zzzz"'), findsOneWidget);
  });
  testWidgets('a network failure shows offline and a retry that works', (
    tester,
  ) async {
    final harness = await open(
      tester,
      prepare: (harness) => harness.catalog.searchError = BridgeError(
        kind: BridgeErrorKind.network,
        detail: 'x',
      ),
    );
    await type(tester, 'a');
    expect(find.text('Tidak ada koneksi'), findsOneWidget);
    harness.catalog.searchError = null;
    harness.catalog.searchResult = page([card(1, title: 'Ketemu')]);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Ketemu'), findsOneWidget);
  });
  testWidgets('opening a result remembers the search and opens its detail', (
    tester,
  ) async {
    final harness = await open(
      tester,
      prepare: (harness) =>
          harness.catalog.searchResult = page([card(7, title: 'Pilihan')]),
    );
    await type(tester, 'pil');
    await tester.tap(find.text('Pilihan'));
    await tester.pumpAndSettle();
    final visit = harness.visits.single;
    expect(visit.path, Routes.detail);
    final request = visit.extra! as DetailRequest;
    expect(request.reference, card(7).reference);
    expect(request.kind, MediaKindDto.anime);
    expect(harness.library.searchHistory, ['pil']);
  });
  testWidgets('the filter sheet hides other formats', (tester) async {
    await open(
      tester,
      prepare: (harness) => harness.catalog.searchResult = page([
        card(1, title: 'Serial', format: 'TV'),
        card(2, title: 'Layar Lebar', format: 'MOVIE'),
      ]),
    );
    await type(tester, 'a');
    expect(find.text('Serial'), findsOneWidget);
    await chooseFilter(tester, ['format-movie']);
    expect(find.text('Serial'), findsNothing);
    expect(find.text('Layar Lebar'), findsOneWidget);
    expect(find.byKey(const Key('active-Film')), findsOneWidget);
    expect(find.byKey(const Key('filter-badge')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });
  testWidgets('the sheet orders by the best score', (tester) async {
    await open(
      tester,
      prepare: (harness) => harness.catalog.searchResult = page([
        card(1, title: 'Biasa', score: 5),
        card(2, title: 'Terbaik', score: 9.5),
      ]),
    );
    await type(tester, 'a');
    final before = tester.getTopLeft(find.text('Biasa')).dx;
    expect(before, lessThan(tester.getTopLeft(find.text('Terbaik')).dx));
    await chooseFilter(tester, ['order-score']);
    expect(
      tester.getTopLeft(find.text('Terbaik')).dx,
      lessThan(tester.getTopLeft(find.text('Biasa')).dx),
    );
  });
}
