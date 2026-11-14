import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const kolektakuDarkColorScheme = ShadColorScheme(
  background: Color(0xFF0E0E12),
  foreground: Color(0xFFF3F1EC),
  card: Color(0xFF17171D),
  cardForeground: Color(0xFFF3F1EC),
  popover: Color(0xFF202028),
  popoverForeground: Color(0xFFF3F1EC),
  primary: Color(0xFFF5B82E),
  primaryForeground: Color(0xFF16130A),
  secondary: Color(0xFF202028),
  secondaryForeground: Color(0xFFF3F1EC),
  muted: Color(0xFF17171D),
  mutedForeground: Color(0xFFA7A6B0),
  accent: Color(0xFF202028),
  accentForeground: Color(0xFFF3F1EC),
  destructive: Color(0xFFE5484D),
  destructiveForeground: Color(0xFFF3F1EC),
  border: Color(0xFF2A2A33),
  input: Color(0xFF2A2A33),
  ring: Color(0xFFF5B82E),
  selection: Color(0x4DF5B82E),
  custom: {'favorite': Color(0xFFF0386B)},
);

extension KolektakuColorSchemeX on ShadColorScheme {
  Color get favorite => custom['favorite']!;
}
