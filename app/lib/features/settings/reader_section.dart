import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/settings_providers.dart';
import 'settings_edit.dart';
import 'settings_widgets.dart';

class ReaderSection extends ConsumerWidget {
  const ReaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchRow(
          title: 'Lanjut otomatis ke chapter berikutnya',
          hint:
              'Saat menggulir sampai bawah, chapter berikutnya tersambung '
              'di bawahnya dengan pembatas. Kalau mati, kamu memilih sendiri '
              'lewat tombol di akhir chapter.',
          value: settings.continuousReading,
          onChanged: (value) => ref
              .read(settingsProvider.notifier)
              .change((s) => s.copyWith(continuousReading: value)),
        ),
      ],
    );
  }
}
