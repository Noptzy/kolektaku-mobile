import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/home/resume_labels.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../collection/collection_support.dart';

final _now = DateTime.utc(2026, 11, 22, 12);

BigInt _agoSeconds(Duration gap) =>
    BigInt.from(_now.subtract(gap).millisecondsSinceEpoch ~/ 1000);

ProgressDto _progress(
  MediaKindDto kind, {
  required double position,
  required double length,
}) {
  final base = progress(1, kind: kind);
  return ProgressDto(
    reference: base.reference,
    kind: kind,
    unitNumber: base.unitNumber,
    title: base.title,
    position: position,
    length: length,
    updatedAtSecs: base.updatedAtSecs,
    completed: false,
  );
}

void main() {
  group('agoLabel', () {
    String ago(Duration gap) => agoLabel(_now, _agoSeconds(gap));

    test('under a minute is just now', () {
      expect(ago(const Duration(seconds: 20)), 'Baru saja');
    });

    test('minutes and hours count up', () {
      expect(ago(const Duration(minutes: 5)), '5 mnt lalu');
      expect(ago(const Duration(minutes: 59)), '59 mnt lalu');
      expect(ago(const Duration(hours: 2)), '2 jam lalu');
      expect(ago(const Duration(hours: 23)), '23 jam lalu');
    });

    test('a day or so ago is yesterday', () {
      expect(ago(const Duration(hours: 24)), 'Kemarin');
      expect(ago(const Duration(hours: 47)), 'Kemarin');
    });

    test('days, a week, and weeks', () {
      expect(ago(const Duration(days: 3)), '3 hari lalu');
      expect(ago(const Duration(days: 6)), '6 hari lalu');
      expect(ago(const Duration(days: 7)), 'Minggu lalu');
      expect(ago(const Duration(days: 20)), '2 minggu lalu');
    });

    test('a month or more is the longest it says', () {
      expect(ago(const Duration(days: 45)), 'Lebih sebulan lalu');
      expect(agoLabel(_now, BigInt.zero), 'Lebih sebulan lalu');
    });

    test('a time in the future never says negative', () {
      expect(ago(const Duration(minutes: -30)), 'Baru saja');
    });
  });

  group('remainingLabel', () {
    test('an anime counts minutes left, rounding up', () {
      final p = _progress(MediaKindDto.anime, position: 600, length: 1200);
      expect(remainingLabel(p), 'sisa 10 mnt');
      final almost = _progress(MediaKindDto.anime, position: 541, length: 1200);
      expect(remainingLabel(almost), 'sisa 11 mnt');
    });

    test('an anime nearly finished says less than a minute', () {
      final p = _progress(MediaKindDto.anime, position: 1180, length: 1200);
      expect(remainingLabel(p), 'sisa kurang dari 1 mnt');
      final over = _progress(MediaKindDto.anime, position: 1500, length: 1200);
      expect(remainingLabel(over), 'sisa kurang dari 1 mnt');
    });

    test('a comic says which page of how many', () {
      final p = _progress(MediaKindDto.manga, position: 7, length: 24);
      expect(remainingLabel(p), 'halaman 7 dari 24');
    });

    test('a novel says which paragraph of how many', () {
      final p = _progress(MediaKindDto.novel, position: 40, length: 120);
      expect(remainingLabel(p), 'paragraf 40 dari 120');
    });

    test('nothing is claimed when the length is unknown', () {
      for (final kind in MediaKindDto.values) {
        expect(
          remainingLabel(_progress(kind, position: 3, length: 0)),
          isNull,
          reason: kind.name,
        );
      }
    });
  });

  group('percentDone', () {
    test('rounds and clamps', () {
      expect(
        percentDone(_progress(MediaKindDto.anime, position: 620, length: 1000)),
        62,
      );
      expect(
        percentDone(
          _progress(MediaKindDto.anime, position: 2000, length: 1000),
        ),
        100,
      );
      expect(
        percentDone(_progress(MediaKindDto.anime, position: 5, length: 0)),
        0,
      );
    });
  });
}
