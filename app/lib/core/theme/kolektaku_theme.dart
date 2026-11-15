import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'accent_palette.dart';
import 'kolektaku_color_scheme.dart';
import 'kolektaku_text.dart';
import 'kolektaku_tokens.dart';

const _sheetStroke = Color(0xFF3A3A46);

ShadSheetTheme _sheetTheme(ShadColorScheme scheme) {
  return ShadSheetTheme(
    radius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
    removeBorderRadiusWhenTiny: false,
    backgroundColor: scheme.card,
    border: Border.all(color: _sheetStroke, width: 1.5),
    shadows: [
      BoxShadow(
        color: scheme.primary.withValues(alpha: 0.12),
        blurRadius: 28,
        offset: const Offset(0, -6),
      ),
    ],
  );
}

ShadThemeData kolektakuDarkTheme({Color accent = defaultAccentColor}) {
  final scheme = kolektakuColorScheme(accent);
  return ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    textTheme: kolektakuTextTheme(),
    radius: BorderRadius.circular(Radii.poster),
    sheetTheme: _sheetTheme(scheme),
  );
}
