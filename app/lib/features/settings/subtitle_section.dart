import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/subtitle_style.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/settings_providers.dart';
import '../../src/rust/dto/settings.dart';
import 'settings_edit.dart';
import 'settings_labels.dart';
import 'settings_widgets.dart';
import 'swatch_row.dart';

List<Swatch<SubtitleColorDto>> get _inkSwatches => [
  for (final option in inkOptions)
    (option.$1, subtitleInk(option.$1), option.$2),
];

List<Swatch<SubtitleBoxColorDto>> get _boxSwatches => [
  for (final option in boxInkOptions)
    (option.$1, subtitleBoxInk(option.$1), option.$2),
];

class SubtitleSection extends ConsumerWidget {
  const SubtitleSection({super.key});

  void _change(WidgetRef ref, SettingsDto Function(SettingsDto) edit) {
    ref.read(settingsProvider.notifier).change(edit);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceRow<SubtitleLanguageDto>(
          title: 'Bahasa',
          hint:
              'Kalau bahasa pilihanmu tidak ada di video, dipakai bahasa '
              'lain yang tersedia.',
          options: languageOptions,
          value: settings.subtitleLanguage,
          onChanged: (value) =>
              _change(ref, (s) => s.copyWith(subtitleLanguage: value)),
        ),
        ChoiceRow<SubtitleSizeDto>(
          title: 'Ukuran',
          options: sizeOptions,
          value: settings.subtitleSize,
          onChanged: (value) =>
              _change(ref, (s) => s.copyWith(subtitleSize: value)),
        ),
        SwatchRow<SubtitleColorDto>(
          title: 'Warna teks',
          options: _inkSwatches,
          value: settings.subtitleColor,
          onChanged: (value) =>
              _change(ref, (s) => s.copyWith(subtitleColor: value)),
        ),
        ChoiceRow<SubtitleEdgeDto>(
          title: 'Tepi teks',
          hint: 'Garis tepi hitam membuat teks tetap terbaca di adegan terang.',
          options: edgeOptions,
          value: settings.subtitleEdge,
          onChanged: (value) =>
              _change(ref, (s) => s.copyWith(subtitleEdge: value)),
        ),
        SwatchRow<SubtitleBoxColorDto>(
          title: 'Warna latar',
          options: _boxSwatches,
          value: settings.subtitleBoxColor,
          onChanged: (value) =>
              _change(ref, (s) => s.copyWith(subtitleBoxColor: value)),
        ),
        ChoiceRow<SubtitleBoxOpacityDto>(
          title: 'Kepekatan latar',
          options: opacityOptions,
          value: settings.subtitleBoxOpacity,
          onChanged: (value) =>
              _change(ref, (s) => s.copyWith(subtitleBoxOpacity: value)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.screenGutter,
            vertical: Spacing.md,
          ),
          child: ShadButton.outline(
            key: const Key('subtitle-reset'),
            onPressed: () =>
                _change(ref, (current) => current.withDefaultSubtitleLook()),
            child: const Text('Kembalikan bawaan'),
          ),
        ),
      ],
    );
  }
}
