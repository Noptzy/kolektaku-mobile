import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/accent_palette.dart';

void main() {
  test('ten presets are offered and the default is the current yellow', () {
    expect(accentPresets, hasLength(10));
    expect(accentPresets.first.color, defaultAccentColor);
  });

  test('every hue from 0 to 345 every 15 degrees builds a distinct color', () {
    final colors = [
      for (var hue = 0; hue < 360; hue += 15)
        accentColorFromHue(hue.toDouble()),
    ];
    expect(colors.toSet().length, colors.length);
  });

  test('hue wraps around 360 degrees', () {
    expect(accentColorFromHue(0), accentColorFromHue(360));
    expect(accentColorFromHue(10), accentColorFromHue(370));
  });

  test('a bright accent gets dark text and a dark accent gets light text', () {
    expect(accentForegroundFor(defaultAccentColor), darkTextOnAccent);
    expect(accentForegroundFor(const Color(0xFF1E1B4B)), lightTextOnAccent);
  });

  test('selection keeps the accent hue but becomes translucent', () {
    final selection = accentSelectionColor(defaultAccentColor);
    expect(selection.a, closeTo(0.3, 0.01));
    expect(selection.r, defaultAccentColor.r);
    expect(selection.g, defaultAccentColor.g);
    expect(selection.b, defaultAccentColor.b);
  });

  test(
    'the default accent selection matches the color it replaces exactly',
    () {
      expect(accentSelectionColor(defaultAccentColor), const Color(0x4DF5B82E));
    },
  );

  test('hex parsing accepts only #RRGGBB and round-trips', () {
    expect(parseAccentHex('#1E90FF'), const Color(0xFF1E90FF));
    expect(parseAccentHex('#1e90ff'), const Color(0xFF1E90FF));
    expect(parseAccentHex('1E90FF'), isNull);
    expect(parseAccentHex('#1E90F'), isNull);
    expect(parseAccentHex('orange'), isNull);
    expect(accentToHex(const Color(0xFF1E90FF)), '#1E90FF');
  });

  test('a broken stored hex falls back to the default accent', () {
    expect(accentColorFromSettings('not-a-color'), defaultAccentColor);
    expect(accentColorFromSettings('#1E90FF'), const Color(0xFF1E90FF));
  });
}
