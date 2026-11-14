import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/genre_tint.dart';

void main() {
  group('genreHue', () {
    test('is stable for a name and ignores case', () {
      expect(genreHue('Racing'), genreHue('Racing'));
      expect(genreHue('Racing'), genreHue('racing'));
    });

    test('stays inside the colour wheel', () {
      for (final name in ['A', 'Combat Sports', 'Idols (Female)', '']) {
        final hue = genreHue(name);
        expect(hue, inInclusiveRange(0, 359));
      }
    });

    test('different names rarely land on the same hue', () {
      final names = ['Racing', 'Pets', 'Medical', 'Workplace', 'Samurai'];
      expect(names.map(genreHue).toSet().length, greaterThan(3));
    });
  });

  group('genreTint', () {
    test('has a lighter start and a darker end', () {
      final tint = genreTint('Racing');
      expect(tint.length, 2);
      final first = HSLColor.fromColor(tint.first).lightness;
      final last = HSLColor.fromColor(tint.last).lightness;
      expect(first, greaterThan(last));
    });
  });
}
