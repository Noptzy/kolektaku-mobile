import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

ShadTextTheme kolektakuTextTheme() {
  return ShadTextTheme(
    custom: {
      'heroTitle': const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.1,
      ),
      'sectionTitle': const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      'cardTitle': const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      'cardMeta': const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.3,
      ),
      'badge': const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.1,
      ),
      'rank': const TextStyle(
        fontSize: 112,
        fontWeight: FontWeight.w900,
        height: 0.9,
      ),
    },
  );
}

extension KolektakuTextX on ShadTextTheme {
  TextStyle get heroTitle => custom['heroTitle']!;
  TextStyle get sectionTitle => custom['sectionTitle']!;
  TextStyle get cardTitle => custom['cardTitle']!;
  TextStyle get cardMeta => custom['cardMeta']!;
  TextStyle get badge => custom['badge']!;
  TextStyle get rank => custom['rank']!;
}
