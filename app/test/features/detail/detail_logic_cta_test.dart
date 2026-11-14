import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/detail/cta_plan.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'detail_support.dart';

void main() {
  group('planCta', () {
    final all = units(12).units;

    CtaPlan plan({
      MediaKindDto kind = MediaKindDto.anime,
      List? list,
      last,
      bool film = false,
    }) => planCta(
      kind: kind,
      units: list == null ? all : units(0).units,
      last: last,
      isFilm: film,
    );

    test('no units disables the button', () {
      final result = plan(list: const []);
      expect(result.enabled, isFalse);
      expect(result.label, 'Belum ada sumber');
    });

    test('nothing watched starts at the first episode', () {
      final result = plan();
      expect(result.label, 'Tonton Episode 1');
      expect(result.unit!.number, 1);
      expect(result.startAt, isNull);
    });

    test('a film starts with a film label', () {
      expect(plan(film: true).label, 'Tonton film');
    });

    test('an unfinished episode continues from where it stopped', () {
      final result = plan(last: progress(5, position: 321.4));
      expect(result.label, 'Lanjut Ep. 5');
      expect(result.startAt, const Duration(seconds: 321));
    });

    test('a finished episode points at the next one', () {
      final result = plan(last: progress(5, completed: true));
      expect(result.label, 'Tonton Episode 6');
      expect(result.unit!.number, 6);
      expect(result.startAt, isNull);
    });

    test('a finished last episode offers watching from the start', () {
      final result = plan(last: progress(12, completed: true));
      expect(result.label, 'Tonton dari awal');
      expect(result.unit!.number, 1);
    });

    test('manga reads chapters and never starts mid way', () {
      final fresh = plan(kind: MediaKindDto.manga);
      expect(fresh.label, 'Baca Chapter 1');
      final resumed = plan(
        kind: MediaKindDto.manga,
        last: progress(3, kind: MediaKindDto.manga),
      );
      expect(resumed.label, 'Lanjut Ch. 3');
      expect(resumed.startAt, isNull);
    });
  });
}
