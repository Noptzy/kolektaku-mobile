import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/year_filter.dart';
import 'package:kolektaku/features/search/search_tab_screen.dart';

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
    await type(tester, 'a');
    expect(find.text('Biasa'), findsOneWidget);
    await chooseFilter(tester, ['year-$year']);
    expect(find.text('Tahun Itu'), findsOneWidget);
    expect(find.text('Biasa'), findsNothing);
    expect(find.byKey(Key('active-$year')), findsOneWidget);
    final ask = harness.catalog.discoverAsks.single;
    expect(ask['query'], 'a');
    expect(ask['year'], YearFilter.only(year));
  });

  testWidgets('older years share one option and ask for an open range', (
    tester,
  ) async {
    final cutoff = DateTime.now().year - 12;
    final harness = await open(
      tester,
      prepare: (harness) => harness.catalog.discoverResult = page([
        card(2, title: 'Klasik', year: 1999),
      ]),
    );
    await type(tester, 'a');
    await chooseFilter(tester, ['year-le$cutoff']);
    expect(find.text('Klasik'), findsOneWidget);
    final year = harness.catalog.discoverAsks.single['year']! as YearFilter;
    expect(year.fromYear, isNull);
    expect(year.toYear, cutoff);
  });

  testWidgets('a year with nothing in the catalog says so', (tester) async {
    await open(tester);
    await type(tester, 'a');
    await chooseFilter(tester, ['year-${DateTime.now().year}']);
    expect(find.text('Tidak ada hasil'), findsOneWidget);
  });

  testWidgets('removing the year goes back to the normal results', (
    tester,
  ) async {
    final year = DateTime.now().year;
    await open(
      tester,
      prepare: (harness) {
        harness.catalog.searchResult = page([card(1, title: 'Biasa')]);
        harness.catalog.discoverResult = page([card(2, title: 'Tahun Itu')]);
      },
    );
    await type(tester, 'a');
    await chooseFilter(tester, ['year-$year']);
    await tester.tap(find.byKey(Key('active-$year')));
    await tester.pumpAndSettle();
    expect(find.text('Biasa'), findsOneWidget);
    expect(find.text('Tahun Itu'), findsNothing);
  });

  testWidgets('removing an active filter shows everything again', (
    tester,
  ) async {
    await open(
      tester,
      prepare: (harness) => harness.catalog.searchResult = page([
        card(1, title: 'Serial', format: 'TV'),
        card(2, title: 'Layar Lebar', format: 'MOVIE'),
      ]),
    );
    await type(tester, 'a');
    await chooseFilter(tester, ['format-movie']);
    await tester.tap(find.byKey(const Key('active-Film')));
    await tester.pumpAndSettle();
    expect(find.text('Serial'), findsOneWidget);
    expect(find.byKey(const Key('filter-badge')), findsNothing);
  });
  testWidgets('reset in the sheet clears every choice', (tester) async {
    await open(
      tester,
      prepare: (harness) => harness.catalog.searchResult = page([
        card(1, title: 'Serial', format: 'TV'),
        card(2, title: 'Layar Lebar', format: 'MOVIE'),
      ]),
    );
    await type(tester, 'a');
    await chooseFilter(tester, ['format-movie']);
    await tester.tap(find.byKey(const Key('open-filters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-reset')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('filter-apply')));
    await tester.pumpAndSettle();
    expect(find.text('Serial'), findsOneWidget);
    expect(find.text('Layar Lebar'), findsOneWidget);
  });
  testWidgets('the filter button is in the header but no chips yet', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('open-filters')), findsOneWidget);
    expect(find.byKey(const Key('filter-badge')), findsNothing);
  });
  testWidgets('the next page loads by itself without a button', (tester) async {
    final harness = await open(
      tester,
      prepare: (harness) =>
          harness.catalog.onSearch = (kind, query, number) async => number == 1
          ? page([card(1, title: 'Satu')], hasNext: true)
          : page([card(2, title: 'Dua')]),
    );
    await type(tester, 'a');
    expect(harness.catalog.searches.last, 'anime|a|2');
    expect(find.text('Dua'), findsOneWidget);
    expect(find.byKey(const Key('load-more')), findsNothing);
  });
  testWidgets('a failing next page offers a retry instead of looping', (
    tester,
  ) async {
    var calls = 0;
    final harness = await open(
      tester,
      prepare: (harness) =>
          harness.catalog.onSearch = (kind, query, number) async {
            calls++;
            if (number == 1) {
              return page([card(1, title: 'Satu')], hasNext: true);
            }
            if (calls <= 2) throw StateError('down');
            return page([card(2, title: 'Dua')]);
          },
    );
    await type(tester, 'a');
    expect(harness.catalog.searches.length, 2);
    expect(find.text('Satu'), findsOneWidget);
    expect(find.byKey(const Key('load-more')), findsOneWidget);
    await tester.tap(find.byKey(const Key('load-more')));
    await tester.pumpAndSettle();
    expect(find.text('Dua'), findsOneWidget);
  });
  testWidgets('a filter nothing matches stops auto loading after a few pages', (
    tester,
  ) async {
    final harness = await open(
      tester,
      prepare: (harness) =>
          harness.catalog.onSearch = (kind, query, number) async => page([
            for (var i = 0; i < 20; i++)
              card(number * 100 + i, title: 'P$number-$i', year: 2020),
          ], hasNext: true),
    );
    await type(tester, 'a');
    await chooseFilter(tester, ['format-movie']);
    await tester.pumpAndSettle();
    expect(harness.catalog.searches.length, lessThanOrEqualTo(8));
    expect(find.byKey(const Key('load-more')), findsOneWidget);
    expect(find.text('Tidak ada hasil'), findsOneWidget);
  });
}
