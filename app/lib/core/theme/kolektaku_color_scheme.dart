import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'accent_palette.dart';

const _background = Color(0xFF0E0E12);
const _foreground = Color(0xFFF3F1EC);
const _card = Color(0xFF17171D);
const _popover = Color(0xFF202028);
const _secondary = Color(0xFF202028);
const _mutedForeground = Color(0xFFA7A6B0);
const _surfaceAccent = Color(0xFF202028);
const _destructive = Color(0xFFC62F34);
const _border = Color(0xFF2A2A33);
const _customColors = {
  'favorite': Color(0xFFF0386B),
  'score': Color(0xFF3DBE6A),
  'onScore': Color(0xFF04140A),
  'scrim': Color(0xCC0E0E12),
};

const kolektakuDarkColorScheme = ShadColorScheme(
  background: _background,
  foreground: _foreground,
  card: _card,
  cardForeground: _foreground,
  popover: _popover,
  popoverForeground: _foreground,
  primary: defaultAccentColor,
  primaryForeground: darkTextOnAccent,
  secondary: _secondary,
  secondaryForeground: _foreground,
  muted: _card,
  mutedForeground: _mutedForeground,
  accent: _surfaceAccent,
  accentForeground: _foreground,
  destructive: _destructive,
  destructiveForeground: _foreground,
  border: _border,
  input: _border,
  ring: defaultAccentColor,
  selection: Color(0x4DF5B82E),
  custom: _customColors,
);

ShadColorScheme kolektakuColorScheme(Color accent) {
  return ShadColorScheme(
    background: _background,
    foreground: _foreground,
    card: _card,
    cardForeground: _foreground,
    popover: _popover,
    popoverForeground: _foreground,
    primary: accent,
    primaryForeground: accentForegroundFor(accent),
    secondary: _secondary,
    secondaryForeground: _foreground,
    muted: _card,
    mutedForeground: _mutedForeground,
    accent: _surfaceAccent,
    accentForeground: _foreground,
    destructive: _destructive,
    destructiveForeground: _foreground,
    border: _border,
    input: _border,
    ring: accent,
    selection: accentSelectionColor(accent),
    custom: _customColors,
  );
}

extension KolektakuColorSchemeX on ShadColorScheme {
  Color get favorite => custom['favorite']!;
  Color get score => custom['score']!;
  Color get onScore => custom['onScore']!;
  Color get scrim => custom['scrim']!;
}
