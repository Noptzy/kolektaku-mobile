import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/accent_palette.dart';
import '../../core/theme/accent_preview_provider.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/settings_providers.dart';
import '../../src/rust/dto/settings.dart';
import 'hue_slider.dart';
import 'settings_edit.dart';
import 'settings_widgets.dart';
import 'swatch_row.dart';

List<Swatch<String>> get _presetSwatches => [
  for (final preset in accentPresets)
    (accentToHex(preset.color), preset.color, preset.label),
];

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  void _save(WidgetRef ref, SettingsDto Function(SettingsDto) edit) {
    ref.read(settingsProvider.notifier).change(edit);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    final accent = accentColorFromSettings(settings.accent);
    final hue = HSLColor.fromColor(accent).hue;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwatchRow<String>(
          title: 'Warna siap pakai',
          options: _presetSwatches,
          value: settings.accent,
          onChanged: (hex) => _save(ref, (s) => s.copyWith(accent: hex)),
        ),
        const SettingsHeading('Warna sendiri'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
          child: HueSlider(
            hue: hue,
            onChanged: (value) => ref
                .read(accentPreviewProvider.notifier)
                .set(accentColorFromHue(value)),
            onChangeEnd: (value) {
              _save(
                ref,
                (s) =>
                    s.copyWith(accent: accentToHex(accentColorFromHue(value))),
              );
              ref.read(accentPreviewProvider.notifier).set(null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.screenGutter,
            vertical: Spacing.md,
          ),
          child: ShadButton.outline(
            key: const Key('appearance-reset'),
            onPressed: () => _save(
              ref,
              (s) => s.copyWith(accent: accentToHex(defaultAccentColor)),
            ),
            child: const Text('Kembalikan bawaan'),
          ),
        ),
      ],
    );
  }
}
