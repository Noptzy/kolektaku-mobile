import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/dev/gallery/sample_media.dart';
import 'package:kolektaku/features/home/home_mix.dart';
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'home_support.dart';

String titles(List<HeroEntry> mixed) =>
    mixed.map((item) => item.card.title).join('|');

String labels(List<HeroEntry> mixed) =>
    mixed.map((item) => item.label).join('|');

void main() {
  group('mixHero', () {
    test(
      'each category of the favored kind gets a slide, then two of the other',
      () {
        final mixed = mixHero(
          anime: homeOf('A'),
          manga: homeOf('M'),
          prefersAnime: true,
        );
        expect(
          titles(mixed),
          'A rating 1|A terbaru 1|A tamat 1|A comeback 1|A top 1|M rating 1|M terbaru 1',
        );
        expect(mixed.first.kind, MediaKindDto.anime);
        expect(mixed.last.kind, MediaKindDto.manga);
      },
    );

    test(
      'every slide keeps its category label and the other kind is named',
      () {
        final mixed = mixHero(
          anime: homeOf('A'),
          manga: homeOf('M'),
          prefersAnime: true,
        );
        expect(
          labels(mixed),
          'Rating tertinggi minggu ini|Terbaru minggu ini|Baru saja tamat minggu ini|'
          'Baru saja comeback|Sedang ramai minggu ini|'
          'Komik · Rating tertinggi minggu ini|Komik · Terbaru minggu ini',
        );
      },
    );

    test(
      'preferring comics puts their categories first and names anime last',
      () {
        final mixed = mixHero(
          anime: homeOf('A'),
          manga: homeOf('M'),
          prefersAnime: false,
        );
        expect(mixed.first.kind, MediaKindDto.manga);
        expect(mixed.first.label, 'Rating tertinggi minggu ini');
        expect(mixed.last.label, 'Anime · Terbaru minggu ini');
      },
    );

    test('an empty category is skipped and the others keep their labels', () {
      final home = HomeDto(
        sections: [
          HomeSectionDto(id: 'top_rated', cards: const []),
          ...homeOf('A', weekly: false).sections,
        ],
        notices: const [],
      );
      final mixed = mixHero(anime: home, manga: null, prefersAnime: true);
      expect(labels(mixed), 'Sedang ramai minggu ini');
      expect(titles(mixed), 'A top 1');
    });

    test('a title that tops two categories shows up only once', () {
      final shared = sampleCard(5, title: 'Dobel');
      final home = HomeDto(
        sections: [
          HomeSectionDto(id: 'top_rated', cards: [shared]),
          HomeSectionDto(
            id: 'new_week',
            cards: [
              shared,
              sampleCard(6, title: 'Lain'),
            ],
          ),
        ],
        notices: const [],
      );
      final mixed = mixHero(anime: home, manga: null, prefersAnime: true);
      expect(titles(mixed), 'Dobel|Lain');
    });

    test(
      'a missing favored kind is replaced by the other one without a prefix',
      () {
        final mixed = mixHero(
          anime: homeOf('A'),
          manga: null,
          prefersAnime: false,
        );
        expect(mixed.every((item) => item.kind == MediaKindDto.anime), isTrue);
        expect(mixed.first.label, 'Rating tertinggi minggu ini');
        expect(mixed.length, 5);
      },
    );

    test('a home with only trending still gets a slide', () {
      final mixed = mixHero(
        anime: homeOf('A', weekly: false),
        manga: null,
        prefersAnime: true,
      );
      expect(mixed.length, 1);
    });

    test('nothing loaded means no hero', () {
      expect(mixHero(anime: null, manga: null, prefersAnime: true), isEmpty);
    });
  });

  group('heroLabelOf', () {
    test('known sections have their wording and unknown ones fall back', () {
      expect(heroLabelOf('top_rated'), 'Rating tertinggi minggu ini');
      expect(heroLabelOf('returning'), 'Baru saja comeback');
      expect(heroLabelOf('whatever'), 'whatever');
    });
  });

  group('mergeResume', () {
    test('all kinds are mixed with the newest first', () {
      final merged = mergeResume([
        [progress(MediaKindDto.anime, 'Lama', updated: 5)],
        [
          progress(MediaKindDto.manga, 'Baru', updated: 50),
          progress(MediaKindDto.manga, 'Tengah', updated: 20),
        ],
        [progress(MediaKindDto.novel, 'Novel', updated: 30)],
      ]);
      expect(merged.map((item) => item.title), [
        'Baru',
        'Novel',
        'Tengah',
        'Lama',
      ]);
    });

    test('the list is capped', () {
      final many = [
        for (var i = 0; i < 20; i++)
          progress(MediaKindDto.anime, 'T$i', updated: i),
      ];
      expect(mergeResume([many, const []]).length, resumeLimit);
    });
  });

  test(
    'rail titles name the kind and the verb on the hero button follows it',
    () {
      expect(railTitle(MediaKindDto.anime, 'trending'), 'Top 10 anime');
      expect(railTitle(MediaKindDto.manga, 'popular'), 'Komik populer');
      expect(railTitle(MediaKindDto.anime, 'latest'), 'Episode baru');
      expect(railTitle(MediaKindDto.manga, 'latest'), 'Chapter baru');
      expect(actionLabelFor(MediaKindDto.anime), 'Tonton');
      expect(actionLabelFor(MediaKindDto.manga), 'Baca');
      expect(otherKind(MediaKindDto.anime), MediaKindDto.manga);
    },
  );
}
