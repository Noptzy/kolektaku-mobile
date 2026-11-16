import 'package:flutter/widgets.dart' show EditableText, Key;
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/collection/collection_screen.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/detail/detail_screen.dart';
import 'package:kolektaku/features/search/search_tab_screen.dart';
import 'package:kolektaku/features/settings/settings_screen.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/src/rust/error.dart';

import '../features/collection/collection_support.dart' as collection;
import '../features/detail/detail_support.dart';
import '../features/search/search_support.dart' as search;
import 'audit_harness.dart';

const _long =
    'Tensei shitara Slime Datta Ken Gaiden: Tempest no Kyoudai to Sekai no '
    'Hate de Hajimaru Mono Gatari yang Judulnya Sangat Panjang Sekali';

DetailRequest _request(MediaKindDto kind) =>
    DetailRequest(kind: kind, reference: ref(filmId));

void main() {
  testWidgets('detail of an anime with a very long title and source', (
    tester,
  ) async {
    await auditScreen(
      tester,
      name: 'detail anime',
      screen: () => DetailScreen(request: _request(MediaKindDto.anime)),
      prepare: (harness) {
        harness.catalog.detailResult = catalogView(
          head: detail(
            head: summary(title: _long, english: _long),
          ),
          sources: [
            link('a', name: 'Sumber anime 1'),
            link('b', name: 'Sumber anime 2'),
          ],
        );
        harness.catalog.unitsResult = units(12);
      },
    );
  });

  testWidgets('detail of an anime whose match is doubtful', (tester) async {
    await auditScreen(
      tester,
      name: 'detail ragu',
      screen: () => DetailScreen(request: _request(MediaKindDto.anime)),
      prepare: (harness) {
        final doubtful = SourceLinkDto(
          source: 'a',
          sourceName: 'Sumber anime 1',
          item: 'item-a',
          confidence: 0.7,
          manual: false,
          needsHint: true,
          matchedTitle: _long,
          variants: const [],
        );
        harness.catalog.detailResult = catalogView(sources: [doubtful]);
        harness.catalog.unitsResult = units(12, source: 'a');
      },
    );
  });

  testWidgets('detail of a novel nobody has shows its empty state whole', (
    tester,
  ) async {
    await auditScreen(
      tester,
      name: 'detail novel kosong',
      screen: () => DetailScreen(request: _request(MediaKindDto.novel)),
      prepare: (harness) {
        harness.catalog.detailResult = catalogView(
          head: detail(
            head: summary(kind: MediaKindDto.novel, title: _long),
          ),
        );
        harness.catalog.unitsResult = units(0);
      },
      after: (tester) async {
        expect(find.text('Bukan ini?'), findsWidgets);
      },
    );
  });

  testWidgets('detail of a title that has not aired yet', (tester) async {
    await auditScreen(
      tester,
      name: 'detail belum tayang',
      screen: () => DetailScreen(request: _request(MediaKindDto.anime)),
      prepare: (harness) {
        harness.catalog.detailResult = catalogView(
          head: detail(head: summary(status: 'NOT_YET_RELEASED')),
        );
        harness.catalog.unitsResult = units(0);
      },
    );
  });

  testWidgets('detail when the list fails to load', (tester) async {
    await auditScreen(
      tester,
      name: 'detail gagal',
      screen: () => DetailScreen(request: _request(MediaKindDto.manga)),
      prepare: (harness) {
        harness.catalog.detailResult = catalogView(
          head: detail(head: summary(kind: MediaKindDto.manga)),
        );
        harness.catalog.unitsError = const BridgeError(
          kind: BridgeErrorKind.notFound,
          detail: 'x',
        );
      },
    );
  });

  testWidgets('search with long titles and side matches', (tester) async {
    await auditScreen(
      tester,
      name: 'cari',
      screen: () => const SearchTabScreen(),
      prepare: (harness) {
        harness.catalog.searchResult = search.page([
          for (var i = 0; i < 6; i++) search.card(i, title: _long),
        ]);
        harness.catalog.mangaSearchResult = search.page([
          for (var i = 0; i < 8; i++)
            search.card(50 + i, title: _long, format: 'MANGA'),
        ]);
        harness.catalog.novelSearchResult = search.page([
          for (var i = 0; i < 8; i++)
            search.card(70 + i, title: _long, format: 'NOVEL'),
        ]);
      },
      after: (tester) async {
        await tester.enterText(find.byType(EditableText), 'kimetsu');
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('the collection with long favourites', (tester) async {
    await auditScreen(
      tester,
      name: 'koleksi',
      screen: () => const CollectionScreen(),
      prepare: (harness) {
        harness.library.favoriteResult = [
          for (var i = 1; i <= 9; i++) collection.favorite(i, title: _long),
        ];
      },
    );
  });

  testWidgets('the collection of novels with long highlights', (tester) async {
    await auditScreen(
      tester,
      name: 'koleksi sorotan',
      screen: () => const CollectionScreen(),
      prepare: (harness) {
        for (var i = 1; i <= 4; i++) {
          harness.highlights.seed(
            reference: ref(i),
            chapter: i.toDouble(),
            block: i,
            start: 0,
            quote: '$_long. ' * 6,
            title: _long,
          );
        }
      },
      after: (tester) async {
        await tester.tap(find.byKey(const Key('kind-novel')));
        await tester.pumpAndSettle();
      },
    );
  });

  testWidgets('the settings home', (tester) async {
    await auditScreen(
      tester,
      name: 'pengaturan',
      screen: () => const SettingsScreen(),
    );
  });
}
