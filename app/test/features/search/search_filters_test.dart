import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/search/search_filters.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'search_support.dart';

void main() {
  group('SearchFormat', () {
    test('all accepts anything including an unknown format', () {
      expect(SearchFormat.all.accepts(null), isTrue);
      expect(SearchFormat.all.accepts('MOVIE'), isTrue);
    });

    test('a specific format needs a known matching value', () {
      expect(SearchFormat.tv.accepts('TV'), isTrue);
      expect(SearchFormat.tv.accepts('tv_short'), isTrue);
      expect(SearchFormat.tv.accepts('MOVIE'), isFalse);
      expect(SearchFormat.tv.accepts(null), isFalse);
      expect(SearchFormat.movie.accepts('MOVIE'), isTrue);
      expect(SearchFormat.ova.accepts('ONA'), isTrue);
      expect(SearchFormat.ova.accepts('SPECIAL'), isTrue);
    });

    test('each kind gets its own chips, led by all', () {
      expect(SearchFormat.forKind(MediaKindDto.anime), [
        SearchFormat.all,
        SearchFormat.tv,
        SearchFormat.movie,
        SearchFormat.ova,
        SearchFormat.music,
      ]);
      expect(SearchFormat.forKind(MediaKindDto.manga).first, SearchFormat.all);
      expect(
        SearchFormat.forKind(MediaKindDto.manga),
        contains(SearchFormat.oneShot),
      );
    });
  });

  group('SearchOrder', () {
    final cards = [
      card(1, score: 6, year: 2010),
      card(2, score: null, year: null),
      card(3, score: 9, year: 2024),
      card(4, score: 7.5, year: 2018),
    ];

    List<int> ids(List cards) => [
      for (final c in cards) (c.reference.id as BigInt).toInt(),
    ];

    test('relevance keeps the order from the source', () {
      expect(ids(SearchOrder.relevance.apply(cards)), [1, 2, 3, 4]);
    });

    test('score puts the best first and unknown last', () {
      expect(ids(SearchOrder.score.apply(cards)), [3, 4, 1, 2]);
    });

    test('newest puts the latest year first and unknown last', () {
      expect(ids(SearchOrder.newest.apply(cards)), [3, 4, 1, 2]);
    });

    test('sorting never changes the original list', () {
      SearchOrder.score.apply(cards);
      expect(ids(cards), [1, 2, 3, 4]);
    });
  });

  test('filterCards filters first and then sorts', () {
    final cards = [
      card(1, format: 'MOVIE', score: 6),
      card(2, format: 'TV', score: 7),
      card(3, format: 'MOVIE', score: 9),
    ];
    final result = filterCards(cards, SearchFormat.movie, SearchOrder.score);
    expect([for (final c in result) c.title], ['Judul 3', 'Judul 1']);
  });
}
