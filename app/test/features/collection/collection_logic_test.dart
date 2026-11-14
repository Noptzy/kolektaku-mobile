import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/collection/collection_logic.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../../features/detail/detail_support.dart';

ProgressDto progress({
  MediaKindDto kind = MediaKindDto.anime,
  double unit = 3,
  double position = 600,
  double length = 1200,
  bool completed = false,
  int saved = 0,
}) {
  return ProgressDto(
    reference: ref(7),
    kind: kind,
    unitNumber: unit,
    title: 'Judul',
    position: position,
    length: length,
    updatedAtSecs: BigInt.from(saved),
    completed: completed,
  );
}

void main() {
  group('agoLabel', () {
    String ago(int secondsBack) =>
        agoLabel(BigInt.from(1000000), 1000000 + secondsBack);

    test('the first minute is just now', () {
      expect(ago(0), 'Baru saja');
      expect(ago(59), 'Baru saja');
    });

    test('minutes, hours and days count up', () {
      expect(ago(60), '1 menit lalu');
      expect(ago(59 * 60), '59 menit lalu');
      expect(ago(3600), '1 jam lalu');
      expect(ago(23 * 3600), '23 jam lalu');
      expect(ago(24 * 3600), 'Kemarin');
      expect(ago(3 * 24 * 3600), '3 hari lalu');
    });

    test('weeks, months and years follow', () {
      expect(ago(7 * 24 * 3600), '1 minggu lalu');
      expect(ago(21 * 24 * 3600), '3 minggu lalu');
      expect(ago(60 * 24 * 3600), '2 bulan lalu');
      expect(ago(400 * 24 * 3600), '1 tahun lalu');
    });

    test('a time in the future is still just now', () {
      expect(ago(-500), 'Baru saja');
    });
  });

  group('historyLine', () {
    test('an episode shows how far it was watched in percent', () {
      expect(historyLine(progress()), 'Episode 3 · 50%');
    });

    test('a chapter shows the page it stopped at', () {
      final line = historyLine(
        progress(kind: MediaKindDto.manga, unit: 12, position: 4, length: 20),
      );
      expect(line, 'Chapter 12 · Hal. 4 dari 20');
    });

    test('a finished one says so', () {
      expect(historyLine(progress(completed: true)), 'Episode 3 · Selesai');
    });

    test('without a length only the unit is shown', () {
      expect(historyLine(progress(length: 0)), 'Episode 3');
    });

    test('the percent never leaves its range', () {
      expect(historyLine(progress(position: 5000)), 'Episode 3 · 100%');
      expect(historyLine(progress(position: -5)), 'Episode 3 · 0%');
    });
  });

  group('historyFraction', () {
    test('is the share watched while unfinished', () {
      expect(historyFraction(progress()), 0.5);
    });

    test('is nothing for finished or unknown lengths', () {
      expect(historyFraction(progress(completed: true)), isNull);
      expect(historyFraction(progress(length: 0)), isNull);
    });
  });

  test('a history key tells titles and units apart', () {
    expect(historyKey(progress(unit: 1)), isNot(historyKey(progress(unit: 2))));
    expect(historyKey(progress(unit: 1)), historyKey(progress(unit: 1)));
  });

  test('a favorite becomes a card with its own title and cover', () {
    final card = favoriteCard(
      FavoriteDto(
        reference: ref(9),
        kind: MediaKindDto.anime,
        title: 'Favorit',
        coverUrl: 'https://img.test/c.jpg',
        addedAtSecs: BigInt.zero,
      ),
    );
    expect(card.title, 'Favorit');
    expect(card.coverUrl, 'https://img.test/c.jpg');
    expect(card.reference, ref(9));
  });

  test('the wording follows the kind', () {
    expect(collectionTitle(MediaKindDto.anime), 'Anime');
    expect(collectionTitle(MediaKindDto.manga), 'Komik');
    expect(emptyHistory(MediaKindDto.anime), contains('ditonton'));
    expect(emptyHistory(MediaKindDto.manga), contains('dibaca'));
    expect(emptyFavorites(MediaKindDto.manga), contains('komik'));
  });
}
