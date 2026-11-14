import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/search/search_filters.dart';
import 'package:kolektaku/features/search/search_notifier.dart';
import 'package:kolektaku/features/search/search_state.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/error.dart';

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
  testWidgets('starts idle with nothing loaded', (tester) async {
    final rig = Rig();
    expect(rig.state.isIdle, isTrue);
    expect(rig.state.status, SearchStatus.idle);
  });
  testWidgets('typing waits 300 ms before searching', (tester) async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)]);
    rig.notifier.onQueryChanged('kimi');
    await tester.pump(const Duration(milliseconds: 299));
    expect(rig.catalog.searches, isEmpty);
    await settle(tester, 1);
    expect(rig.catalog.searches, ['anime|kimi|1']);
    expect(rig.state.cards.length, 1);
    expect(rig.state.status, SearchStatus.loaded);
  });
  testWidgets('fast typing collapses into one search for the last text', (
    tester,
  ) async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)]);
    for (final text in ['k', 'ki', 'kim', 'kimi']) {
      rig.notifier.onQueryChanged(text);
      await tester.pump(const Duration(milliseconds: 100));
    }
    await settle(tester);
    expect(rig.catalog.searches, ['anime|kimi|1']);
  });
  testWidgets('clearing the text returns to idle and cancels the search', (
    tester,
  ) async {
    final rig = Rig();
    rig.notifier.onQueryChanged('kimi');
    rig.notifier.onQueryChanged('   ');
    await settle(tester);
    expect(rig.catalog.searches, isEmpty);
    expect(rig.state.isIdle, isTrue);
  });
  testWidgets('submit searches at once and remembers the query', (
    tester,
  ) async {
    final rig = Rig();
    rig.catalog.searchResult = page([card(1)]);
    rig.notifier.onQueryChanged('kimi no nawa');
    await rig.notifier.submit();
    await tester.pump();
    expect(rig.catalog.searches, ['anime|kimi no nawa|1']);
    expect(rig.library.searchHistory, ['kimi no nawa']);
    await settle(tester);
    expect(rig.catalog.searches.length, 1);
  });
  testWidgets('load more appends the next page and stops at the end', (
    tester,
  ) async {
    final rig = Rig();
    rig.catalog.onSearch = (kind, query, number) async =>
        number == 1 ? page([card(1)], hasNext: true) : page([card(2)]);
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    expect(rig.state.hasNext, isTrue);
    await rig.notifier.loadMore();
    expect([for (final c in rig.state.cards) c.title], ['Judul 1', 'Judul 2']);
    expect(rig.state.hasNext, isFalse);
    await rig.notifier.loadMore();
    expect(rig.catalog.searches.length, 2);
  });
  testWidgets('a slow earlier answer never overwrites a newer one', (
    tester,
  ) async {
    final rig = Rig();
    final slow = Completer<CardPageDto>();
    rig.catalog.onSearch = (kind, query, number) =>
        query == 'old' ? slow.future : Future.value(page([card(2)]));
    rig.notifier.onQueryChanged('old');
    await settle(tester);
    rig.notifier.onQueryChanged('new');
    await settle(tester);
    slow.complete(page([card(1)]));
    await tester.pump();
    expect(rig.state.query, 'new');
    expect([for (final c in rig.state.cards) c.title], ['Judul 2']);
  });
  testWidgets('a failure is kept and retry recovers', (tester) async {
    final rig = Rig();
    rig.catalog.searchError = BridgeError(
      kind: BridgeErrorKind.network,
      detail: 'x',
    );
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    expect(rig.state.status, SearchStatus.failed);
    expect(rig.state.error, isA<BridgeError>());
    rig.catalog.searchError = null;
    rig.catalog.searchResult = page([card(1)]);
    await rig.notifier.retry();
    expect(rig.state.status, SearchStatus.loaded);
    expect(rig.state.error, isNull);
  });
  testWidgets('a failure is never retried by itself', (tester) async {
    final rig = Rig();
    rig.catalog.searchError = BridgeError(
      kind: BridgeErrorKind.unavailable,
      detail: 'x',
    );
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    await tester.pump(const Duration(seconds: 30));
    expect(rig.catalog.searches.length, 1);
  });
  testWidgets('format and order change the view without a new request', (
    tester,
  ) async {
    final rig = Rig();
    rig.catalog.searchResult = page([
      card(1, format: 'MOVIE', score: 6),
      card(2, format: 'TV', score: 9),
    ]);
    rig.notifier.onQueryChanged('a');
    await settle(tester);
    rig.notifier.setFormat(SearchFormat.movie);
    expect(rig.state.visible.length, 1);
    rig.notifier.setFormat(SearchFormat.all);
    rig.notifier.setOrder(SearchOrder.score);
    expect(rig.state.visible.first.title, 'Judul 2');
    expect(rig.catalog.searches.length, 1);
  });
  testWidgets('filters survive a cleared query', (tester) async {
    final rig = Rig();
    rig.notifier.setFormat(SearchFormat.tv);
    rig.notifier.onQueryChanged('a');
    rig.notifier.onQueryChanged('');
    expect(rig.state.format, SearchFormat.tv);
  });
}
