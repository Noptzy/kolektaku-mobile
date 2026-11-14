import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/dates.dart';
import 'package:kolektaku/core/labels.dart';
import 'package:kolektaku/features/detail/detail_info.dart';
import 'package:kolektaku/features/detail/episode_window.dart';
import 'package:kolektaku/features/detail/info_section.dart';
import 'package:kolektaku/src/rust/dto/credits.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'detail_support.dart';

void main() {
  group('labels', () {
    test('formats and statuses are in Indonesian', () {
      expect(formatLabel('MOVIE'), 'Film');
      expect(formatLabel('TV_SHORT'), 'TV');
      expect(formatLabel('ONE_SHOT'), 'One-shot');
      expect(formatLabel(null), isNull);
      expect(statusLabel('FINISHED', MediaKindDto.anime), 'Tamat');
      expect(statusLabel('RELEASING', MediaKindDto.anime), 'Sedang tayang');
      expect(statusLabel('RELEASING', MediaKindDto.manga), 'Berlanjut');
      expect(
        statusLabel('NOT_YET_RELEASED', MediaKindDto.manga),
        'Belum terbit',
      );
    });

    test('unit counts name the unit by kind', () {
      expect(unitCountLabel(12, MediaKindDto.anime), '12 eps');
      expect(unitCountLabel(40, MediaKindDto.manga), '40 ch');
      expect(unitCountLabel(null, MediaKindDto.anime), '');
    });

    test('relations have Indonesian names and a safe fallback', () {
      expect(relationLabel('SEQUEL'), 'Lanjutan');
      expect(relationLabel('PREQUEL'), 'Sebelumnya');
      expect(relationLabel('SOMETHING_NEW'), 'Terkait');
    });
  });
  group('dates', () {
    test('a full date, a month and a bare year', () {
      expect(
        formatDate(const DateDto(year: 2016, month: 8, day: 26)),
        '26 Agu 2016',
      );
      expect(formatDate(const DateDto(year: 2016, month: 8)), 'Agu 2016');
      expect(formatDate(const DateDto(year: 2016)), '2016');
      expect(formatDate(const DateDto()), isNull);
    });
  });
  group('DetailInfo', () {
    test('a catalog detail joins year, format, status and count', () {
      final info = DetailInfo.fromView(catalogView(), MediaKindDto.anime);
      expect(info.title, 'Kimi no Na wa.');
      expect(info.altTitle, 'Your Name.');
      expect(info.meta, '2016 · Film · Tamat · 1 eps');
      expect(info.limited, isFalse);
      expect(info.isFilm, isTrue);
      expect(info.score, 8.6);
    });

    test('the synopsis of a catalog detail is plain text', () {
      final info = DetailInfo.fromView(
        catalogView(
          head: detail(description: 'Satu<br><br><b>Dua</b> &amp; tiga'),
        ),
        MediaKindDto.anime,
      );
      expect(info.synopsis, 'Satu\n\nDua & tiga');
    });

    test('the second title is skipped when it equals the first', () {
      final info = DetailInfo.fromView(
        catalogView(
          head: detail(head: summary(english: 'Kimi no Na wa.')),
        ),
        MediaKindDto.anime,
      );
      expect(info.altTitle, isNull);
    });

    test('a site-only detail is marked limited and has no score', () {
      final info = DetailInfo.fromView(siteView(), MediaKindDto.anime);
      expect(info.limited, isTrue);
      expect(info.title, 'Judul Situs');
      expect(info.altTitle, 'Alt');
      expect(info.meta, '2024 · TV · 12 eps');
      expect(info.score, isNull);
      expect(info.isFilm, isFalse);
    });
  });
  group('info rows', () {
    test('empty values are left out', () {
      final rows = infoRows(detail(), MediaKindDto.anime);
      final names = rows.map((row) => row.$1);
      expect(names, containsAll(['Format', 'Status', 'Studio', 'Mulai']));
      expect(rows.firstWhere((row) => row.$1 == 'Durasi').$2, '107 menit');
      expect(
        rows.firstWhere((row) => row.$1 == 'Sumber cerita').$2,
        'Orisinal',
      );
      expect(rows.every((row) => row.$2.isNotEmpty), isTrue);
    });

    test('the next airing episode is listed', () {
      final rows = infoRows(
        detail(
          nextAiring: NextAiringDto(
            episode: 5,
            airingAtSecs: BigInt.from(1800000000),
          ),
        ),
        MediaKindDto.anime,
      );
      expect(
        rows.firstWhere((row) => row.$1 == 'Tayang berikutnya').$2,
        startsWith('Episode 5, '),
      );
    });
  });
  group('episode windows', () {
    test('a short list has no windows', () {
      expect(windowsFor(50), isEmpty);
    });

    test('a long list is cut in windows of fifty with a short last one', () {
      final windows = windowsFor(120);
      expect(windows.length, 3);
      expect((windows[0].start, windows[0].end), (0, 50));
      expect((windows[2].start, windows[2].end), (100, 120));
    });

    test('labels show the first and last number of the window', () {
      final sorted = sortedUnits(units(120).units, descending: false);
      expect(windowsFor(120)[1].label(sorted), '51-100');
    });

    test('sorting never changes the source list', () {
      final source = units(3).units.reversed.toList();
      expect(sortedUnits(source, descending: false).first.number, 1);
      expect(sortedUnits(source, descending: true).first.number, 3);
      expect(source.first.number, 3);
    });

    test('finding a number gives its window and index', () {
      final sorted = sortedUnits(units(120).units, descending: false);
      expect(windowIndexOf(sorted, 75), 1);
      expect(windowIndexOf(sorted, 999), 0);
      expect(indexOfNumber(sorted, 75), 74);
      expect(indexOfNumber(sorted, 999), isNull);
    });

    test('first and next unit', () {
      final all = units(3).units;
      expect(firstUnit(all)!.number, 1);
      expect(firstUnit(const []), isNull);
      expect(unitAfter(all, 1)!.number, 2);
      expect(unitAfter(all, 3), isNull);
    });
  });
}
