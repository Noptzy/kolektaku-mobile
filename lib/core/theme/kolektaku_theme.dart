import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'kolektaku_color_scheme.dart';

ShadThemeData kolektakuDarkTheme() {
  return ShadThemeData(
    brightness: Brightness.dark,
    colorScheme: kolektakuDarkColorScheme,
  );
}
