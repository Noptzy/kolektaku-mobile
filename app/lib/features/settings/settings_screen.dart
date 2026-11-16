import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/settings_providers.dart';
import '../../data/providers/source_providers.dart';
import '../../widgets/tab_title.dart';
import '../update/update_controller.dart';
import '../update/update_labels.dart';
import 'settings_logic.dart';
import 'settings_pages.dart';
import 'settings_row.dart';
import 'settings_summary.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Widget _row(BuildContext context, SettingsPage page, String summary) {
    return SettingsRow(
      key: Key('settings-row-${page.slug}'),
      icon: page.icon,
      title: page.title,
      summary: summary,
      onTap: () => context.push(page.path),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final statuses = ref.watch(sourceStatusProvider).value ?? const [];
    final version = ref.watch(appVersionProvider).value;
    final update = ref.watch(updateControllerProvider);
    return ColoredBox(
      color: ShadTheme.of(context).colorScheme.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TabTitle('Pengaturan'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: Spacing.xxl),
                children: [
                  SettingsGroup(
                    title: 'Preferensi',
                    children: [
                      _row(
                        context,
                        SettingsPage.preference,
                        preferenceSummary(settings),
                      ),
                      _row(
                        context,
                        SettingsPage.appearance,
                        appearanceSummary(settings),
                      ),
                      _row(
                        context,
                        SettingsPage.translation,
                        translationSummary(settings),
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: 'Menonton',
                    children: [
                      _row(
                        context,
                        SettingsPage.sourceChoice,
                        animeSourceSummary(settings, statuses),
                      ),
                      _row(
                        context,
                        SettingsPage.subtitle,
                        subtitleSummary(settings),
                      ),
                      _row(
                        context,
                        SettingsPage.player,
                        playerSummary(settings),
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: 'Aplikasi',
                    children: [
                      _row(
                        context,
                        SettingsPage.sources,
                        sourcesSummary(statuses),
                      ),
                      _row(
                        context,
                        SettingsPage.update,
                        updateSummary(update, version),
                      ),
                      _row(context, SettingsPage.about, versionLabel(version)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
