import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'kolektaku_color_scheme.dart';
import 'kolektaku_text.dart';
import 'kolektaku_tokens.dart';

const _sheetStroke = Color(0xFF3A3A46);

ShadSheetTheme _sheetTheme() {
  return ShadSheetTheme(
    radius: const BorderRadius.vertical(top: Radius.circular(Radii.sheet)),
    removeBorderRadiusWhenTiny: false,
    backgroundColor: kolektakuDarkColorScheme.card,
    border: Border.all(color: _sheetStroke, width: 1.5),
    shadows: [
      BoxShadow(
        color: kolektakuDarkColorScheme.primary.withValues(alpha: 0.12),
        blurRadius: 28,
        offset: const Offset(0, -6),
      ),
    ],
  );
}

ShadThemeData kolektakuDarkTheme() {
  return ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: kolektakuDarkColorScheme,
    textTheme: kolektakuTextTheme(),
    radius: BorderRadius.circular(Radii.poster),
    sheetTheme: _sheetTheme(),
  );
}
