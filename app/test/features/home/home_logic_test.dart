import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/features/home/genre_cover.dart';
import 'package:kolektaku/features/home/home_sections.dart';
import 'package:kolektaku/features/home/resume_card.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

HomeDto home() => HomeDto(
  sections: [
    HomeSectionDto(id: 'trending', cards: sampleCards(12)),
    HomeSectionDto(id: 'popular', cards: sampleCards(3)),
  ],
  notices: const [],
);

ProgressDto progress({
  MediaKindDto kind = MediaKindDto.anime,
  double unit = 5,
  double position = 300,
  double length = 1200,
}) => ProgressDto(
  reference: sampleCard(9).reference,
  kind: kind,
  unitNumber: unit,
  title: 'Judul',
  position: position,
  length: length,
  updatedAtSecs: BigInt.zero,
  completed: false,
);

void main() {
  group('sections', () {
    test('a missing section is empty', () {
      expect(cardsOf(home(), 'seasonal'), isEmpty);
      expect(cardsOf(home(), 'popular').length, 3);
    });

    test('the resume title follows the kind', () {
      expect(resumeTitle(MediaKindDto.anime), 'Lanjut nonton');
      expect(resumeTitle(MediaKindDto.manga), 'Lanjut baca');
    });

    test('units are eps for anime and chapter for comics', () {
      expect(unitLabelFor(MediaKindDto.anime), 'eps');
      expect(unitLabelFor(MediaKindDto.manga), 'chapter');
    });

    test('a genre image comes from the first card that has a cover', () {
      final cards = [
        sampleCard(1),
        MediaCardDto(
          reference: sampleCard(2).reference,
          title: 't',
          coverUrl: 'https://img.test/2.jpg',
          genres: const ['Drama'],
          limited: false,
          sources: const [],
        ),
      ];
      final data = HomeDto(
        sections: [HomeSectionDto(id: 'trending', cards: cards)],
        notices: const [],
      );
      expect(genreImage('drama', data), 'https://img.test/2.jpg');
      expect(genreImage('Horror', data), isNull);
    });
  });

  group('featured genres', () {
    MediaCardDto withGenre(String genre) => MediaCardDto(
      reference: sampleCard(1).reference,
      title: 't',
      coverUrl: 'https://img.test/c.jpg',
      genres: [genre],
      limited: false,
      sources: const [],
    );

    test('genres with artwork come first and the grid holds six', () {
      final data = HomeDto(
        sections: [
          HomeSectionDto(id: 'trending', cards: [withGenre('Drama')]),
        ],
        notices: const [],
      );
      final genres = [
        for (final name in ['A', 'B', 'C', 'D', 'E', 'F', 'Drama', 'G'])
          GenreDto(slug: name.toLowerCase(), name: name),
      ];
      final picked = featuredGenres(genres, const {}, data);
      expect(picked.length, 6);
      expect(picked.first.name, 'Drama');
      expect(picked.skip(1).map((genre) => genre.name), [
        'A',
        'B',
        'C',
        'D',
        'E',
      ]);
    });

    test('with no artwork at all the site order is kept', () {
      final data = HomeDto(sections: const [], notices: const []);
      final genres = [
        for (final name in ['A', 'B', 'C'])
          GenreDto(slug: name.toLowerCase(), name: name),
      ];
      expect(
        featuredGenres(genres, const {}, data).map((genre) => genre.name),
        ['A', 'B', 'C'],
      );
    });
  });

  group('resume cards', () {
    test('whole unit numbers have no decimals', () {
      expect(unitText(5), '5');
      expect(unitText(5.5), '5.5');
    });

    test('the meta names the unit by kind', () {
      expect(resumeMeta(MediaKindDto.anime, 5), 'Episode 5');
      expect(resumeMeta(MediaKindDto.manga, 12), 'Chapter 12');
    });

    test('progress is the watched fraction and never passes one', () {
      expect(resumeFraction(progress(position: 300, length: 1200)), 0.25);
      expect(resumeFraction(progress(position: 2000, length: 1200)), 1);
      expect(resumeFraction(progress(length: 0)), isNull);
    });

    test('the card keeps the title and shows the episode as meta', () {
      final card = resumeCard(progress());
      expect(card.title, 'Judul');
      expect(card.latestLabel, 'Episode 5');
      expect(card.limited, isFalse);
    });
  });
}
