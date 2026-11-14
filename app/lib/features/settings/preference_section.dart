import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/settings_providers.dart';
import 'settings_edit.dart';
import 'settings_widgets.dart';

class PreferenceSection extends ConsumerWidget {
  const PreferenceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(currentSettingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChoiceRow<bool>(
          title: 'Lebih suka',
          hint:
              'Beranda menampilkan lebih banyak anime atau komik sesuai '
              'pilihanmu.',
          options: const [(true, 'Anime'), (false, 'Komik')],
          value: settings.prefersAnime,
          onChanged: (value) => ref
              .read(settingsProvider.notifier)
              .change((current) => current.copyWith(prefersAnime: value)),
        ),
      ],
    );
  }
}
