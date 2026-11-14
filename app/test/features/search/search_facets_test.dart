import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/search/search_facets.dart';
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

Future<void> settle(WidgetTester tester) async {
  await tester.pump(searchDebounce + const Duration(milliseconds: 50));
  await tester.pump();
}

void main() {
  testWidgets('genre, airing and source go to the catalog together', (
    tester,
  ) async {
    final rig = Rig();
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    await rig.notifier.setFacets(
      genre: 'Action',
      airing: SearchAiring.finished,
      origin: SearchOrigin.manga,
    );
    final ask = rig.catalog.discoverAsks.single;
    expect(ask['genre'], 'Action');
    expect(ask['status'], 'FINISHED');
    expect(ask['origin'], 'MANGA');
    expect(ask['query'], 'a');
  });

  testWidgets('a format joins the catalog request once another filter is on', (
    tester,
  ) async {
    final rig = Rig();
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    await rig.notifier.applyFilters(
      format: SearchFormat.movie,
      order: SearchOrder.relevance,
      genre: 'Drama',
    );
    expect(rig.catalog.discoverAsks.single['formats'], ['MOVIE']);
    expect(rig.catalog.discoverAsks.length, 1);
  });

  testWidgets('applying several filters at once asks the catalog once', (
    tester,
  ) async {
    final rig = Rig();
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    await rig.notifier.applyFilters(
      format: SearchFormat.tv,
      order: SearchOrder.score,
      genre: 'Comedy',
      airing: SearchAiring.releasing,
      origin: SearchOrigin.original,
    );
    expect(rig.catalog.discoverAsks.length, 1);
    expect(rig.catalog.searches.length, 1);
  });

  testWidgets('filters alone browse the catalog without a query', (
    tester,
  ) async {
    final rig = Rig();
    rig.catalog.discoverResult = page([card(5, title: 'Hasil Filter')]);
    await rig.notifier.setFacets(genre: 'Mystery');
    expect(rig.catalog.discoverAsks.single['query'], isNull);
    expect(rig.state.visible.single.title, 'Hasil Filter');
    expect(rig.state.isIdle, isFalse);
  });

  testWidgets('removing the last filter without a query goes idle again', (
    tester,
  ) async {
    final rig = Rig();
    await rig.notifier.setFacets(genre: 'Mystery');
    await rig.notifier.setFacets();
    expect(rig.state.isIdle, isTrue);
    expect(rig.state.cards, isEmpty);
  });

  testWidgets('the same choice again asks nothing', (tester) async {
    final rig = Rig();
    await rig.notifier.setFacets(genre: 'Mystery');
    await rig.notifier.setFacets(genre: 'Mystery');
    expect(rig.catalog.discoverAsks.length, 1);
  });

  testWidgets('clearing the text keeps browsing by the filters', (
    tester,
  ) async {
    final rig = Rig();
    await rig.notifier.setFacets(genre: 'Mystery');
    rig.notifier.onQueryChanged('abc');
    await settle(tester);
    rig.notifier.onQueryChanged('');
    await settle(tester);
    expect(rig.catalog.discoverAsks.last['query'], isNull);
    expect(rig.state.genre, 'Mystery');
  });

  testWidgets('resetting clears every facet and runs the plain search', (
    tester,
  ) async {
    final rig = Rig();
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    await rig.notifier.setFacets(
      genre: 'Action',
      airing: SearchAiring.hiatus,
      origin: SearchOrigin.videoGame,
    );
    rig.notifier.resetFilters();
    await tester.pump();
    expect(rig.state.genre, isNull);
    expect(rig.state.airing, SearchAiring.all);
    expect(rig.state.origin, SearchOrigin.all);
    expect(rig.catalog.searches.length, 2);
  });

  testWidgets('the query that last ran is remembered for the studio hint', (
    tester,
  ) async {
    final rig = Rig();
    rig.notifier.onQueryChanged('ghibli');
    expect(rig.state.ranQuery, isEmpty);
    await settle(tester);
    expect(rig.state.ranQuery, 'ghibli');
  });

  test('facets know their catalog names and labels', () {
    expect(SearchAiring.all.apiName, isNull);
    expect(SearchAiring.upcoming.apiName, 'NOT_YET_RELEASED');
    expect(SearchOrigin.lightNovel.apiName, 'LIGHT_NOVEL');
    expect(
      SearchOrigin.values.every((origin) => origin.label.isNotEmpty),
      isTrue,
    );
    expect(searchGenres, isNot(contains('Hentai')));
    expect(searchGenres, isNot(contains('Ecchi')));
    expect(popularStudios.toSet(), hasLength(popularStudios.length));
  });
}
