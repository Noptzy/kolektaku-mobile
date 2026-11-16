import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/cta_plan.dart';
import 'package:kolektaku/features/detail/maybe_match.dart';
import 'package:kolektaku/features/detail/release_note.dart';
import 'package:kolektaku/src/rust/dto/credits.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import 'detail_support.dart';

SourceLinkDto doubtful(String id, {bool manual = false, bool hint = true}) =>
    SourceLinkDto(
      source: id,
      sourceName: id,
      item: 'item-$id',
      confidence: 0.7,
      manual: manual,
      needsHint: hint,
      matchedTitle: 'Kimetsu no Yaiba (Dub ID)',
      variants: const [],
    );

void main() {
  group('doubtfulLink', () {
    final links = [doubtful('a'), doubtful('b', hint: false)];

    test('an anime whose active source is unsure asks the person', () {
      final found = doubtfulLink(
        kind: MediaKindDto.anime,
        links: links,
        current: 'a',
      );
      expect(found?.source, 'a');
    });

    test('a sure active source asks nothing even if another is unsure', () {
      expect(
        doubtfulLink(kind: MediaKindDto.anime, links: links, current: 'b'),
        isNull,
      );
    });

    test('before the units load the best link is the one in question', () {
      expect(
        doubtfulLink(kind: MediaKindDto.anime, links: links, current: null),
        isNotNull,
      );
    });

    test('comics and novels never ask', () {
      for (final kind in [MediaKindDto.manga, MediaKindDto.novel]) {
        expect(doubtfulLink(kind: kind, links: links, current: 'a'), isNull);
      }
    });

    test('a manual choice is never questioned', () {
      expect(
        doubtfulLink(
          kind: MediaKindDto.anime,
          links: [doubtful('a', manual: true)],
          current: 'a',
        ),
        isNull,
      );
    });

    test('the line names the title the site uses', () {
      expect(
        maybeMatchLine(links.first),
        contains('Kimetsu no Yaiba (Dub ID)'),
      );
    });
  });

  group('unreleased titles', () {
    test('the status decides', () {
      expect(isUnreleased('NOT_YET_RELEASED'), isTrue);
      expect(isUnreleased('FINISHED'), isFalse);
      expect(isUnreleased(null), isFalse);
    });

    test('the date reads in Indonesian and tolerates missing parts', () {
      expect(
        releaseDateLabel(const DateDto(year: 2026, month: 7, day: 3)),
        '3 Jul 2026',
      );
      expect(releaseDateLabel(const DateDto(year: 2027, month: 5)), 'Mei 2027');
      expect(releaseDateLabel(const DateDto(year: 2027)), '2027');
      expect(releaseDateLabel(const DateDto()), isNull);
      expect(releaseDateLabel(null), isNull);
    });

    test('the button explains instead of offering to play', () {
      final plan = planCta(
        kind: MediaKindDto.anime,
        units: units(12).units,
        last: null,
        isFilm: false,
        unreleased: true,
        releaseLabel: 'Jul 2027',
      );
      expect(plan.enabled, isFalse);
      expect(plan.label, 'Belum tayang · Jul 2027');
      final undated = planCta(
        kind: MediaKindDto.anime,
        units: const [],
        last: null,
        isFilm: false,
        unreleased: true,
      );
      expect(undated.label, 'Belum tayang');
    });
  });
}
