import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/year_filter.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/genre/genre_notifier.dart';
import 'package:kolektaku/features/genre/genre_state.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/discover.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/error.dart';
import 'package:kolektaku/src/rust/service/browse.dart';

import '../../support/fake_catalog_gateway.dart';
import '../search/search_support.dart';

const args = (kind: MediaKindDto.manga, slug: 'action', name: 'Action');

class Rig {
  Rig() {
    container = ProviderContainer(
      retry: noRetry,
      overrides: [catalogGatewayProvider.overrideWithValue(catalog)],
    );
    addTearDown(container.dispose);
    container.listen(genreProvider(args), (previous, next) {});
  }

  final FakeCatalogGateway catalog = FakeCatalogGateway();
  late final ProviderContainer container;

  GenreNotifier get notifier => container.read(genreProvider(args).notifier);

  GenreState get state => container.read(genreProvider(args));
}

void main() {
  yearTests();
  test('loads the first page on its own, newest first', () async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)], hasNext: true);
    expect(rig.state.status, GenreStatus.loading);
    await Future<void>.delayed(Duration.zero);
    expect(rig.catalog.genrePages, ['manga|action|1|newest']);
    expect(rig.state.status, GenreStatus.loaded);
    expect(rig.state.hasNext, isTrue);
  });

  test('load more appends and stops at the last page', () async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)], hasNext: true);
    await Future<void>.delayed(Duration.zero);
    rig.catalog.searchResult = page([card(2)]);
    await rig.notifier.loadMore();
    expect(rig.state.cards.length, 2);
    expect(rig.state.hasNext, isFalse);
    await rig.notifier.loadMore();
    expect(rig.catalog.genrePages.length, 2);
  });

  test('changing the order starts again from page one', () async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)], hasNext: true);
    await Future<void>.delayed(Duration.zero);
    await rig.notifier.setOrder(SourceOrderDto.az);
    expect(rig.catalog.genrePages.last, 'manga|action|1|az');
    expect(rig.state.cards.length, 1);
    await rig.notifier.setOrder(SourceOrderDto.az);
    expect(rig.catalog.genrePages.length, 2);
  });

  test('a failure is kept and retry recovers', () async {
    final rig = Rig();
    rig.catalog.onGenre = (kind, slug, number, order) async =>
        throw BridgeError(kind: BridgeErrorKind.unavailable, detail: 'x');
    await Future<void>.delayed(Duration.zero);
    expect(rig.state.status, GenreStatus.failed);
    rig.catalog.onGenre = null;
    rig.catalog.searchResult = page([card(1)]);
    await rig.notifier.retry();
    expect(rig.state.status, GenreStatus.loaded);
    expect(rig.state.error, isNull);
  });

  test('a failure is never retried by itself', () async {
    final rig = Rig();
    rig.catalog.onGenre = (kind, slug, number, order) async =>
        throw BridgeError(kind: BridgeErrorKind.network, detail: 'x');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await Future<void>.delayed(const Duration(seconds: 1));
    expect(rig.catalog.genrePages.length, 1);
  });

  test('an older answer never replaces a newer order', () async {
    final rig = Rig();
    final slow = Completer<CardPageDto>();
    rig.catalog.onGenre = (kind, slug, number, order) =>
        order == SourceOrderDto.newest
        ? slow.future
        : Future.value(page([card(2)]));
    await Future<void>.delayed(Duration.zero);
    await rig.notifier.setOrder(SourceOrderDto.oldest);
    slow.complete(page([card(1)]));
    await Future<void>.delayed(Duration.zero);
    expect(rig.state.order, SourceOrderDto.oldest);
    expect([for (final c in rig.state.cards) c.title], ['Judul 2']);
  });
}

void yearTests() {
  test('a year loads the genre from the catalog instead of the site', () async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)]);
    rig.catalog.discoverResult = page([card(2, year: 2015)], hasNext: true);
    await Future<void>.delayed(Duration.zero);
    await rig.notifier.setYear(const YearFilter.only(2015));
    final ask = rig.catalog.discoverAsks.single;
    expect(ask['genre'], 'Action');
    expect(ask['year'], const YearFilter.only(2015));
    expect(ask['kind'], MediaKindDto.manga);
    expect(rig.state.cards.map((item) => item.title), ['Judul 2']);
    expect(rig.state.hasNext, isTrue);
    expect(rig.catalog.genrePages.length, 1);
  });

  test('clearing the year goes back to the site listing', () async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)]);
    await Future<void>.delayed(Duration.zero);
    await rig.notifier.setYear(const YearFilter.only(2015));
    await rig.notifier.setYear(null);
    expect(rig.catalog.genrePages.length, 2);
    expect(rig.state.year, isNull);
    expect(rig.state.cards.single.title, 'Judul 1');
  });

  test('the chosen order is sent to the catalog as its own order', () async {
    final rig = Rig();
    await Future<void>.delayed(Duration.zero);
    await rig.notifier.apply(SourceOrderDto.az, const YearFilter.upTo(2014));
    final ask = rig.catalog.discoverAsks.single;
    expect(ask['sort'], DiscoverSortDto.az);
    expect((ask['year']! as YearFilter).toYear, 2014);
  });

  test('every site order has a catalog order', () {
    expect(discoverSortOf(SourceOrderDto.newest), DiscoverSortDto.newest);
    expect(discoverSortOf(SourceOrderDto.oldest), DiscoverSortDto.oldest);
    expect(discoverSortOf(SourceOrderDto.az), DiscoverSortDto.az);
    expect(discoverSortOf(SourceOrderDto.za), DiscoverSortDto.za);
  });

  test('applying order and year together loads once', () async {
    final rig = Rig();
    await Future<void>.delayed(Duration.zero);
    await rig.notifier.apply(
      SourceOrderDto.oldest,
      const YearFilter.only(2015),
    );
    expect(rig.catalog.discoverAsks.length, 1);
    expect(rig.catalog.genrePages.length, 1);
  });

  test('applying what is already set loads nothing', () async {
    final rig = Rig();
    await Future<void>.delayed(Duration.zero);
    await rig.notifier.apply(SourceOrderDto.newest, null);
    expect(rig.catalog.genrePages.length, 1);
    expect(rig.catalog.discoverAsks, isEmpty);
  });

  test('more pages keep asking the catalog while a year is set', () async {
    final rig = Rig();
    rig.catalog.discoverResult = page([card(2)], hasNext: true);
    await Future<void>.delayed(Duration.zero);
    await rig.notifier.setYear(const YearFilter.only(2015));
    await rig.notifier.loadMore();
    expect(rig.catalog.discoverAsks.map((ask) => ask['page']), [1, 2]);
    expect(rig.state.cards.length, 2);
  });
}
