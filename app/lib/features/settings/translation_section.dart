import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../core/translation_labels.dart';
import '../../data/providers/settings_providers.dart';
import '../../data/providers/translation_providers.dart';
import '../../src/rust/dto/settings.dart';
import '../../widgets/option_list.dart';
import '../../widgets/pressable.dart';
import '../../widgets/swipe_sheet.dart';
import 'settings_edit.dart';
import 'settings_widgets.dart';

String serviceStateLabel(int? pausedUntilSecs) {
  if (pausedUntilSecs == null) return 'Normal';
  return 'Sedang dibatasi, dicoba lagi pukul '
      '${clockLabelOfSecs(pausedUntilSecs)}';
}

Future<void> showTranslationLanguageSheet(
  BuildContext context, {
  required TranslationLanguageDto current,
  required ValueChanged<TranslationLanguageDto> onPicked,
}) {
  return showSwipeSheet<void>(
    context: context,
    builder: (sheetContext) => ShadSheet(
      title: const Text('Bahasa terjemahan'),
      child: OptionList<TranslationLanguageDto>(
        options: [
          for (final language in TranslationLanguageDto.values)
            (translationLanguageNames[language]!, language),
        ],
        selected: current,
        onPicked: (language) {
          onPicked(language);
          Navigator.of(sheetContext).pop();
        },
      ),
    ),
  );
}

class TranslationSection extends ConsumerWidget {
  const TranslationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final paused = ref.watch(translationPauseProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SettingsHeading('Bahasa terjemahan'),
        _LanguageRow(
          language: settings.translation,
          onTap: () => showTranslationLanguageSheet(
            context,
            current: settings.translation,
            onPicked: (language) => ref
                .read(settingsProvider.notifier)
                .change((s) => s.copyWith(translation: language)),
          ),
        ),
        const SettingsHeading('Keadaan layanan'),
        SettingsNote(serviceStateLabel(paused)),
      ],
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.onTap});

  final TranslationLanguageDto language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    final name = translationLanguageNames[language]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Pressable(
        key: const Key('translation-language-row'),
        onTap: onTap,
        label: 'Bahasa terjemahan, $name',
        minSize: Sizes.touchTarget,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.card,
            borderRadius: Radii.cardShape,
            border: Border.all(color: scheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                Expanded(child: Text(name, style: theme.textTheme.cardTitle)),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: scheme.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
