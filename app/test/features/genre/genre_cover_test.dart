import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/home_providers.dart';
import 'package:kolektaku/features/genre/genre_list_screen.dart';
import 'package:kolektaku/features/home/genre_cover.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/covers.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/widgets/genre_card.dart';
import 'package:kolektaku/widgets/genre_tint.dart';

import '../../support/screen_harness.dart';

const action = GenreDto(slug: 'action', name: 'Action');
const award = GenreDto(slug: 'award', name: 'Award Winning');
const empty = HomeDto(sections: [], notices: []);

HomeDto homeWith(String cover, List<String> genres) {
  final card = MediaCardDto(
    reference: MediaRefDto(
      kind: MediaRefKind.catalog,
      id: BigInt.one,
      source: '',
      item: '',
    ),
    title: 't',
    coverUrl: cover,
    genres: genres,
    limited: false,
    sources: const [],
  );
  return HomeDto(
    sections: [
      HomeSectionDto(id: 'trending', cards: [card]),
    ],
    notices: const [],
  );
}

void main() {
  group('genreCover', () {
    test('the catalog cover of the genre wins', () {
      final home = homeWith('home.jpg', ['Action']);
      expect(genreCover('Action', {'Action': 'own.jpg'}, home), 'own.jpg');
    });

    test('a card of the same genre on the home is the next choice', () {
      final home = homeWith('home.jpg', ['Action']);
      expect(genreCover('Action', const {}, home), 'home.jpg');
    });

    test('a genre nothing matches stays without a picture', () {
      final covers = {'Action': 'a.jpg', 'Drama': 'd.jpg'};
      expect(genreCover('Award Winning', covers, null), isNull);
      final home = homeWith('home.jpg', ['Drama']);
      expect(genreCover('Award Winning', covers, home), isNull);
    });

    test('without any picture at all it stays empty', () {
      expect(genreCover('Action', const {}, null), isNull);
      expect(genreCover('Action', const {}, empty), isNull);
    });

    test('an empty address is not a cover', () {
      expect(genreCover('Action', {'Action': ''}, null), isNull);
    });
  });

  group('featuredGenres', () {
    test('genres with their own cover come before the borrowed ones', () {
      final genres = [
        for (final name in ['A', 'B', 'C', 'D', 'E', 'F', 'G'])
          GenreDto(slug: name.toLowerCase(), name: name),
      ];
      final picked = featuredGenres(genres, {'G': 'g.jpg'}, null);
      expect(picked.first.name, 'G');
      expect(picked.length, 6);
    });
  });

  group('genreCoversProvider', () {
    test('asks once for every genre and keys the answer by name', () async {
      final harness = ScreenHarness();
      harness.catalog.genreResult = const [action, award];
      harness.catalog.coverResult = const [
        GenreCoverDto(genre: 'Action', coverUrl: 'a.jpg'),
        GenreCoverDto(genre: 'Award Winning', coverUrl: 'b.jpg'),
      ];
      final container = harness.container();
      addTearDown(container.dispose);
      final covers = await container.read(
        genreCoversProvider(MediaKindDto.anime).future,
      );
      expect(covers, {'Action': 'a.jpg', 'Award Winning': 'b.jpg'});
      expect(harness.catalog.coverAsks, [
        ['Action', 'Award Winning'],
      ]);
    });

    test('a failing catalog only costs the pictures', () async {
      final harness = ScreenHarness();
      harness.catalog.genreResult = const [action];
      harness.catalog.coverError = StateError('down');
      final container = harness.container();
      addTearDown(container.dispose);
      final covers = await container.read(
        genreCoversProvider(MediaKindDto.anime).future,
      );
      expect(covers, isEmpty);
    });

    test('no genres means no request', () async {
      final harness = ScreenHarness();
      final container = harness.container();
      addTearDown(container.dispose);
      await container.read(genreCoversProvider(MediaKindDto.anime).future);
      expect(harness.catalog.coverAsks, isEmpty);
    });
  });

  testWidgets('a genre without a picture still draws a tinted card', (
    tester,
  ) async {
    final harness = ScreenHarness();
    harness.catalog.genreResult = const [action, award];
    harness.catalog.coverResult = const [
      GenreCoverDto(genre: 'Action', coverUrl: 'https://img.test/a.jpg'),
    ];
    await harness.pump(tester, const GenreListScreen(kind: MediaKindDto.anime));
    final cards = tester.widgetList<GenreCard>(find.byType(GenreCard)).toList();
    expect(cards.length, 2);
    expect(cards.first.imageUrl, 'https://img.test/a.jpg');
    expect(cards.last.imageUrl, isNull);
    expect(
      find.descendant(
        of: find.byType(GenreCard).last,
        matching: find.byType(GenreTint),
      ),
      findsOneWidget,
    );
  });
}
