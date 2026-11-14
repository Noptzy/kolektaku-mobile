import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/home/home_mix.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'home_support.dart';

String titles(List<KindCard> mixed) =>
    mixed.map((item) => item.card.title).join('|');

void main() {
  group('mixHero', () {
    test('a favored kind fills most slots and the other kind the rest', () {
      final mixed = mixHero(
        anime: homeOf('A'),
        manga: homeOf('M'),
        prefersAnime: true,
      );
      expect(mixed.length, 8);
      expect(mixed.where((item) => item.kind == MediaKindDto.anime).length, 6);
      expect(mixed.where((item) => item.kind == MediaKindDto.manga).length, 2);
      expect(mixed.first.kind, MediaKindDto.anime);
    });

    test('preferring manga flips the proportions', () {
      final mixed = mixHero(
        anime: homeOf('A'),
        manga: homeOf('M'),
        prefersAnime: false,
      );
      expect(mixed.where((item) => item.kind == MediaKindDto.manga).length, 6);
      expect(mixed.first.kind, MediaKindDto.manga);
    });

    test('the secondary kind sits in every third slot', () {
      final mixed = mixHero(
        anime: homeOf('A'),
        manga: homeOf('M'),
        prefersAnime: true,
      );
      expect(
        titles(mixed),
        'A top 1|A top 2|M top 1|A top 3|A top 4|M top 2|A top 5|A top 6',
      );
    });

    test('a missing kind is replaced by the other one', () {
      final mixed = mixHero(
        anime: homeOf('A'),
        manga: null,
        prefersAnime: false,
      );
      expect(mixed.length, 8);
      expect(mixed.every((item) => item.kind == MediaKindDto.anime), isTrue);
    });

    test('a short favored list is topped up from the other kind', () {
      final mixed = mixHero(
        anime: homeOf('A', trending: 2),
        manga: homeOf('M'),
        prefersAnime: true,
      );
      expect(mixed.length, 8);
      expect(mixed.where((item) => item.kind == MediaKindDto.anime).length, 2);
    });

    test('nothing loaded means no hero', () {
      expect(mixHero(anime: null, manga: null, prefersAnime: true), isEmpty);
    });
  });

  group('mergeResume', () {
    test('both kinds are mixed with the newest first', () {
      final merged = mergeResume(
        [progress(MediaKindDto.anime, 'Lama', updated: 5)],
        [
          progress(MediaKindDto.manga, 'Baru', updated: 50),
          progress(MediaKindDto.manga, 'Tengah', updated: 20),
        ],
      );
      expect(merged.map((item) => item.title), ['Baru', 'Tengah', 'Lama']);
    });

    test('the list is capped', () {
      final many = [
        for (var i = 0; i < 20; i++)
          progress(MediaKindDto.anime, 'T$i', updated: i),
      ];
      expect(mergeResume(many, const []).length, resumeLimit);
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
