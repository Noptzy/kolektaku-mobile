import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/year_filter.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/search/search_filters.dart';
import 'package:kolektaku/features/search/search_notifier.dart';
import 'package:kolektaku/features/search/search_state.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../../support/fake_catalog_gateway.dart';
import '../../support/fake_library_gateway.dart';
import 'search_support.dart';

const kind = MediaKindDto.anime;

class Rig {
  Rig() {
    container = ProviderContainer(
      retry: noRetry,
      overrides: [
        catalogGatewayProvider.overrideWithValue(catalog),
        libraryGatewayProvider.overrideWithValue(library),
      ],
    );
    addTearDown(container.dispose);
    container.listen(searchProvider(kind), (previous, next) {});
  }

  final FakeCatalogGateway catalog = FakeCatalogGateway();
  final FakeLibraryGateway library = FakeLibraryGateway();
  late final ProviderContainer container;

  SearchNotifier get notifier => container.read(searchProvider(kind).notifier);

  SearchState get state => container.read(searchProvider(kind));
}

Future<void> settle(WidgetTester tester, [int milliseconds = 300]) async {
  await tester.pump(Duration(milliseconds: milliseconds));
  await tester.pump();
}

void main() {
  testWidgets('a year asks the catalog for that year and shows its answer', (
    tester,
  ) async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1, year: 2020), card(2, year: 2001)]);
    rig.catalog.discoverResult = page([card(9, year: 2015)], hasNext: true);
    rig.notifier.onQueryChanged('naruto');
    await settle(tester);
    await rig.notifier.setYear(const YearFilter.only(2015));
    final ask = rig.catalog.discoverAsks.single;
    expect(ask['query'], 'naruto');
    expect(ask['year'], const YearFilter.only(2015));
    expect(ask['page'], 1);
    expect(rig.state.visible.map((item) => item.title), ['Judul 9']);
    expect(rig.state.hasNext, isTrue);
    expect(rig.catalog.searches.length, 1);
  });

  testWidgets('older years go to the catalog as an open ended range', (
    tester,
  ) async {
    final rig = Rig();
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    await rig.notifier.setYear(const YearFilter.upTo(2014));
    final year = rig.catalog.discoverAsks.single['year']! as YearFilter;
    expect(year.fromYear, isNull);
    expect(year.toYear, 2014);
  });

  testWidgets('clearing the year goes back to the plain search', (
    tester,
  ) async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)]);
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    await rig.notifier.setYear(const YearFilter.only(2015));
    await rig.notifier.setYear(null);
    expect(rig.catalog.searches.length, 2);
    expect(rig.catalog.discoverAsks.length, 1);
    expect(rig.state.year, isNull);
    expect(rig.state.visible.single.title, 'Judul 1');
  });

  testWidgets('the same year again asks nothing', (tester) async {
    final rig = Rig();
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    await rig.notifier.setYear(const YearFilter.only(2015));
    await rig.notifier.setYear(const YearFilter.only(2015));
    expect(rig.catalog.discoverAsks.length, 1);
  });

  testWidgets('more pages keep asking for the same year', (tester) async {
    final rig = Rig();
    rig.catalog.discoverResult = page([card(9)], hasNext: true);
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    await rig.notifier.setYear(const YearFilter.only(2015));
    await rig.notifier.loadMore();
    expect(rig.catalog.discoverAsks.map((ask) => ask['page']), [1, 2]);
    expect(rig.state.cards.length, 2);
  });

  testWidgets('a year chosen before typing browses by year alone', (
    tester,
  ) async {
    final rig = Rig();
    await rig.notifier.setYear(const YearFilter.only(2020));
    expect(rig.catalog.discoverAsks.single['query'], isNull);
    expect(rig.state.isIdle, isFalse);
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    expect(rig.catalog.discoverAsks.last['query'], 'a');
    expect(rig.catalog.discoverAsks.last['year'], const YearFilter.only(2020));
    expect(rig.catalog.searches, isEmpty);
  });

  testWidgets('the year survives a cleared query like the other filters', (
    tester,
  ) async {
    final rig = Rig();
    await rig.notifier.setYear(const YearFilter.only(2020));
    rig.notifier.onQueryChanged('a');
    rig.notifier.onQueryChanged('');
    expect(rig.state.year, const YearFilter.only(2020));
  });

  testWidgets('resetting clears format, order and year together', (
    tester,
  ) async {
    final rig = Rig();
    rig.notifier.setFormat(SearchFormat.tv);
    rig.notifier.setOrder(SearchOrder.score);
    await rig.notifier.setYear(const YearFilter.only(2020));
    rig.notifier.resetFilters();
    expect(rig.state.format, SearchFormat.all);
    expect(rig.state.order, SearchOrder.relevance);
    expect(rig.state.year, isNull);
  });

  testWidgets('resetting a year search runs the plain search again', (
    tester,
  ) async {
    final rig = Rig();
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    await rig.notifier.setYear(const YearFilter.only(2015));
    rig.notifier.resetFilters();
    await tester.pump();
    expect(rig.catalog.searches.length, 2);
  });

  testWidgets('pages that add nothing visible pause the auto loading', (
    tester,
  ) async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)], hasNext: true);
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    rig.notifier.setFormat(SearchFormat.movie);
    expect(rig.state.autoLoadPaused, isFalse);
    for (var i = 0; i < maxBarrenPages; i++) {
      await rig.notifier.loadMore();
    }
    expect(rig.state.barrenPages, maxBarrenPages);
    expect(rig.state.autoLoadPaused, isTrue);
  });

  testWidgets('a page with a match or a new filter resets the counter', (
    tester,
  ) async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)], hasNext: true);
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    rig.notifier.setFormat(SearchFormat.movie);
    await rig.notifier.loadMore();
    await rig.notifier.loadMore();
    expect(rig.state.barrenPages, 2);
    rig.notifier.setFormat(SearchFormat.tv);
    expect(rig.state.barrenPages, 0);
    await rig.notifier.loadMore();
    expect(rig.state.barrenPages, 0);
  });
}
