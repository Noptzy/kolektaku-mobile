import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/settings_providers.dart';
import '../../src/rust/dto/settings.dart';
import 'settings_edit.dart';
import 'settings_labels.dart';
import 'settings_widgets.dart';

class PlayerSection extends ConsumerWidget {
  const PlayerSection({super.key});

  void _change(WidgetRef ref, SettingsDto Function(SettingsDto) edit) {
    ref.read(settingsProvider.notifier).change(edit);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceRow<QualityDto>(
          title: 'Kualitas awal',
          hint: 'Hanya berlaku pada sumber yang menyediakan pilihan resolusi.',
          options: qualityOptions,
          value: settings.quality,
          onChanged: (value) => _change(ref, (s) => s.copyWith(quality: value)),
        ),
        SwitchRow(
          title: 'Putar episode berikutnya otomatis',
          value: settings.autoNext,
          onChanged: (value) =>
              _change(ref, (s) => s.copyWith(autoNext: value)),
        ),
        SwitchRow(
          title: 'Lewati intro dan outro otomatis',
          hint:
              'Kalau mati, tombol Lewati muncul saat intro atau outro '
              'berlangsung.',
          value: settings.autoSkip,
          onChanged: (value) =>
              _change(ref, (s) => s.copyWith(autoSkip: value)),
        ),
      ],
    );
  }
}
