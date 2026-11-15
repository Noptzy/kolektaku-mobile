import 'package:flutter/painting.dart';

const defaultAccentColor = Color(0xFFF5B82E);

class AccentPreset {
  const AccentPreset(this.label, this.color);

  final String label;
  final Color color;
}

const accentPresets = <AccentPreset>[
  AccentPreset('Kuning', defaultAccentColor),
  AccentPreset('Oranye', Color(0xFFFF8A3D)),
  AccentPreset('Merah', Color(0xFFEF4444)),
  AccentPreset('Merah muda', Color(0xFFEC4899)),
  AccentPreset('Ungu', Color(0xFFA855F7)),
  AccentPreset('Biru', Color(0xFF3B82F6)),
  AccentPreset('Biru langit', Color(0xFF38BDF8)),
  AccentPreset('Toska', Color(0xFF14B8A6)),
  AccentPreset('Hijau', Color(0xFF22C55E)),
  AccentPreset('Putih', Color(0xFFF3F1EC)),
];

const accentHueSaturation = 0.70;
const accentHueBaseLightness = 0.58;

const _blueHue = 240.0;
const _blueLightnessBoost = 0.14;
const _blueBandHalfWidth = 60.0;

double _hueDistance(double hue, double target) {
  final raw = (hue - target).abs();
  return raw > 180 ? 360 - raw : raw;
}

double _lightnessFor(double hue) {
  final closeness = (1 - _hueDistance(hue, _blueHue) / _blueBandHalfWidth)
      .clamp(0.0, 1.0);
  return accentHueBaseLightness + closeness * _blueLightnessBoost;
}

Color accentColorFromHue(double hueDegrees) {
  final hue = hueDegrees % 360;
  return HSLColor.fromAHSL(
    1,
    hue,
    accentHueSaturation,
    _lightnessFor(hue),
  ).toColor();
}

const darkTextOnAccent = Color(0xFF16130A);
const lightTextOnAccent = Color(0xFFF3F1EC);

double _contrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}

Color accentForegroundFor(Color accent) {
  final darkContrast = _contrastRatio(darkTextOnAccent, accent);
  final lightContrast = _contrastRatio(lightTextOnAccent, accent);
  return darkContrast >= lightContrast ? darkTextOnAccent : lightTextOnAccent;
}

const accentSelectionAlpha = 0x4D / 0xFF;

Color accentSelectionColor(Color accent) {
  return accent.withValues(alpha: accentSelectionAlpha);
}

final _hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

Color? parseAccentHex(String text) {
  if (!_hexPattern.hasMatch(text)) {
    return null;
  }
  final rgb = int.parse(text.substring(1), radix: 16);
  return Color(0xFF000000 | rgb);
}

Color accentColorFromSettings(String hex) =>
    parseAccentHex(hex) ?? defaultAccentColor;

String accentToHex(Color color) {
  final rgb = color.toARGB32() & 0x00FFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
