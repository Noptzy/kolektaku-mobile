import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/settings_providers.dart';
import '../../data/providers/source_providers.dart';
import '../../src/rust/dto/media.dart';
import 'settings_edit.dart';
import 'settings_logic.dart';
import 'source_choice_tile.dart';

const automaticSourceSummary = 'Mengikuti urutan bawaan aplikasi.';

class SourceChoiceSection extends ConsumerWidget {
  const SourceChoiceSection({super.key});

  void _choose(WidgetRef ref, String? id) {
    ref
        .read(settingsProvider.notifier)
        .change((current) => current.withAnimeSource(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = ref.watch(sourceStatusProvider).value ?? const [];
    final entries = numberedSources(statuses, MediaKindDto.anime);
    if (entries.isEmpty) return const SizedBox.shrink();
    final chosen = ref.watch(currentSettingsProvider).animeSource;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SourceChoiceTile(
          key: const Key('source-choice-auto'),
          title: 'Otomatis',
          summary: automaticSourceSummary,
          selected: chosen == null,
          onTap: () => _choose(ref, null),
        ),
        for (final entry in entries)
          SourceChoiceTile(
            key: Key('source-choice-${entry.status.id}'),
            title: sourceLabel(MediaKindDto.anime, entry.number),
            summary: entry.status.summary,
            selected: chosen == entry.status.id,
            onTap: () => _choose(ref, entry.status.id),
          ),
      ],
    );
  }
}
