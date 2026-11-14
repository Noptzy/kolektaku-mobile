import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/router.dart';
import 'core/theme/kolektaku_theme.dart';

class KolektakuApp extends StatelessWidget {
  const KolektakuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp.router(
      title: 'Kolektaku',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: kolektakuDarkTheme(),
      routerConfig: kolektakuRouter,
      builder: (context, child) =>
          FTheme(data: FTheme.neutral.dark.touch, child: child!),
    );
  }
}
