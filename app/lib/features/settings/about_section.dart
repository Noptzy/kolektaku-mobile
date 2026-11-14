import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'about_content.dart';
import 'settings_logic.dart';
import 'settings_widgets.dart';

class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(appVersionProvider).value;
    final notes = notesFor(version);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsNote(versionLabel(version)),
        if (notes.isNotEmpty) ...[
          const SettingsHeading('Yang baru'),
          for (final line in notes) SettingsNote('•  $line'),
        ],
        const SettingsHeading('Sumber data'),
        for (final line in aboutLines) SettingsNote(line),
      ],
    );
  }
}
