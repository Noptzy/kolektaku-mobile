import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/router.dart';
import 'core/theme/accent_palette.dart';
import 'core/theme/accent_preview_provider.dart';
import 'data/providers/settings_providers.dart';
import 'features/scene_search/share_listener.dart';
import 'core/theme/kolektaku_theme.dart';

class KolektakuApp extends ConsumerWidget {
  const KolektakuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentHex = ref.watch(currentSettingsProvider).accent;
    final preview = ref.watch(accentPreviewProvider);
    final accent = preview ?? accentColorFromSettings(accentHex);
    return ShadApp.router(
      title: 'Kolektaku',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: kolektakuDarkTheme(accent: accent),
      routerConfig: kolektakuRouter,
      builder: (context, child) => ShareListener(
        router: kolektakuRouter,
        child: FTheme(data: FTheme.neutral.dark.touch, child: child!),
      ),
    );
  }
}
