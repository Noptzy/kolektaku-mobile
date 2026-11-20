import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/settings_providers.dart';
import 'about_section.dart';
import 'appearance_preview.dart';
import 'appearance_section.dart';
import 'download_section.dart';
import 'player_section.dart';
import 'notification_section.dart';
import 'preference_section.dart';
import 'reader_section.dart';
import 'settings_page_scaffold.dart';
import 'settings_pages.dart';
import 'source_choice_section.dart';
import 'source_status_section.dart';
import 'subtitle_preview.dart';
import 'subtitle_section.dart';
import 'translation_section.dart';
import 'update_panel_section.dart';

class SettingsPageScreen extends ConsumerWidget {
  const SettingsPageScreen({super.key, required this.page});

  final SettingsPage page;

  Widget _body() => switch (page) {
    SettingsPage.preference => const PreferenceSection(),
    SettingsPage.appearance => const AppearanceSection(),
    SettingsPage.translation => const TranslationSection(),
    SettingsPage.sourceChoice => const SourceChoiceSection(),
    SettingsPage.subtitle => const SubtitleSection(),
    SettingsPage.player => const PlayerSection(),
    SettingsPage.reader => const ReaderSection(),
    SettingsPage.downloads => const DownloadSection(),
    SettingsPage.notifications => const NotificationSection(),
    SettingsPage.sources => const SourceStatusSection(),
    SettingsPage.update => const UpdatePanelSection(),
    SettingsPage.about => const AboutSection(),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = switch (page) {
      SettingsPage.subtitle => SubtitlePreview(
        settings: ref.watch(currentSettingsProvider),
      ),
      SettingsPage.appearance => const AppearancePreview(),
      _ => null,
    };
    return SettingsPageScaffold(
      title: page.title,
      intro: page.intro,
      pinned: pinned,
      children: [_body()],
    );
  }
}
