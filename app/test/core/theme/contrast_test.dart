import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_color_scheme.dart';

double _channel(double value) {
  return value <= 0.03928
      ? value / 12.92
      : pow((value + 0.055) / 1.055, 2.4) as double;
}

double _luminance(Color color) {
  return 0.2126 * _channel(color.r) +
      0.7152 * _channel(color.g) +
      0.0722 * _channel(color.b);
}

double contrastRatio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  const scheme = kolektakuDarkColorScheme;

  group('text pairs reach WCAG AA 4.5:1', () {
    final pairs = <String, (Color, Color)>{
      'foreground on background': (scheme.foreground, scheme.background),
      'foreground on card': (scheme.cardForeground, scheme.card),
      'foreground on popover': (scheme.popoverForeground, scheme.popover),
      'muted text on background': (scheme.mutedForeground, scheme.background),
      'muted text on card': (scheme.mutedForeground, scheme.card),
      'muted text on popover': (scheme.mutedForeground, scheme.popover),
      'text on primary': (scheme.primaryForeground, scheme.primary),
      'text on destructive': (scheme.destructiveForeground, scheme.destructive),
      'text on score badge': (scheme.onScore, scheme.score),
    };
    pairs.forEach((name, pair) {
      test(name, () {
        expect(contrastRatio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      });
    });
  });

  group('graphic elements reach 3:1', () {
    test('primary on background', () {
      expect(contrastRatio(scheme.primary, scheme.background), greaterThan(3));
    });

    test('favorite on background', () {
      expect(contrastRatio(scheme.favorite, scheme.background), greaterThan(3));
    });

    test('score on background', () {
      expect(contrastRatio(scheme.score, scheme.background), greaterThan(3));
    });
  });
}
