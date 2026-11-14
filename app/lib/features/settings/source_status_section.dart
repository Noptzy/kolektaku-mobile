import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/gateway_providers.dart';
import '../../data/providers/source_providers.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/skeleton.dart';
import 'settings_logic.dart';
import 'settings_widgets.dart';
import 'source_tile.dart';

class SourceStatusSection extends ConsumerWidget {
  const SourceStatusSection({super.key});

  Future<void> _toggle(WidgetRef ref, String id, bool enabled) async {
    await ref.read(sourceGatewayProvider).setEnabled(id, enabled);
    ref.invalidate(sourceStatusProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(sourceStatusProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sources.when(
          loading: () => const [
            Padding(
              padding: EdgeInsets.all(Spacing.screenGutter),
              child: Skeleton(height: 120, radius: Radii.card),
            ),
          ],
          error: (error, stack) => const [
            SettingsNote('Daftar sumber belum bisa dimuat.'),
          ],
          data: (all) => _kinds(all, ref),
        ),
      ],
    );
  }

  List<Widget> _kinds(List<SourceStatusDto> all, WidgetRef ref) {
    return [
      for (final kind in MediaKindDto.values)
        ..._tiles(numberedSources(all, kind), kind, ref),
    ];
  }

  List<Widget> _tiles(
    List<SourceEntry> entries,
    MediaKindDto kind,
    WidgetRef ref,
  ) {
    return [
      for (final entry in entries)
        SourceTile(
          key: Key('source-${entry.status.id}'),
          label: sourceLabel(kind, entry.number),
          hint: sourceHint(entry.status),
          enabled: entry.status.enabled,
          onChanged: (value) => _toggle(ref, entry.status.id, value),
        ),
      if (allOff(entries))
        SettingsNote(
          kind == MediaKindDto.anime
              ? 'Semua sumber anime mati, jadi tidak ada yang bisa ditonton.'
              : 'Semua sumber komik mati, jadi tidak ada yang bisa dibaca.',
          key: Key('all-off-${kind.name}'),
        ),
    ];
  }
}
