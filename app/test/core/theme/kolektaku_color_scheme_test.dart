import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_color_scheme.dart';

void main() {
  test('building the scheme with the default accent matches the fixed one', () {
    const defaultScheme = kolektakuDarkColorScheme;
    final built = kolektakuColorScheme(defaultScheme.primary);
    expect(built.background, defaultScheme.background);
    expect(built.foreground, defaultScheme.foreground);
    expect(built.card, defaultScheme.card);
    expect(built.primary, defaultScheme.primary);
    expect(built.primaryForeground, defaultScheme.primaryForeground);
    expect(built.ring, defaultScheme.ring);
    expect(built.selection, defaultScheme.selection);
    expect(built.favorite, defaultScheme.favorite);
    expect(built.score, defaultScheme.score);
  });

  test(
    'a different accent only changes primary, ring, selection and its own text',
    () {
      const otherAccent = Color(0xFF3B82F6);
      final built = kolektakuColorScheme(otherAccent);
      expect(built.primary, otherAccent);
      expect(built.ring, otherAccent);
      expect(built.background, kolektakuDarkColorScheme.background);
      expect(built.card, kolektakuDarkColorScheme.card);
      expect(built.foreground, kolektakuDarkColorScheme.foreground);
      expect(built.favorite, kolektakuDarkColorScheme.favorite);
    },
  );
}
