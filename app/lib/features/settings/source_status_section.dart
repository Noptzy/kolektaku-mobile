import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../data/providers/gateway_providers.dart';
import '../../data/providers/source_providers.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/skeleton.dart';
import 'settings_logic.dart';
import 'settings_widgets.dart';
import 'source_ping_board.dart';
import 'source_ping_labels.dart';
import 'source_tile.dart';

class SourceStatusSection extends ConsumerStatefulWidget {
  const SourceStatusSection({super.key});

  @override
  ConsumerState<SourceStatusSection> createState() =>
      _SourceStatusSectionState();
}

class _SourceStatusSectionState extends ConsumerState<SourceStatusSection> {
  late final SourcePingBoard _board = SourcePingBoard(
    ref.read(sourceGatewayProvider),
  );

  Future<void> _toggle(String id, bool enabled) async {
    await ref.read(sourceGatewayProvider).setEnabled(id, enabled);
    ref.invalidate(sourceStatusProvider);
  }

  @override
  void dispose() {
    _board.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(sourceStatusProvider);
    return ListenableBuilder(
      listenable: _board,
      builder: (context, child) => Column(
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
            data: _content,
          ),
        ],
      ),
    );
  }

  List<Widget> _content(List<SourceStatusDto> all) {
    final live = [
      for (final item in all)
        if (item.enabled) item.id,
    ];
    return [
      if (live.isNotEmpty) _pingButton(live),
      for (final kind in MediaKindDto.values)
        ..._tiles(numberedSources(all, kind), kind),
    ];
  }

  Widget _pingButton(List<String> live) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.sm,
        Spacing.screenGutter,
        Spacing.sm,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ShadButton.outline(
          key: const Key('ping-all'),
          enabled: !_board.busy,
          onPressed: () => _board.check(live),
          child: Flexible(
            child: Text(
              _board.busy ? 'Mengecek…' : 'Cek koneksi semua sumber',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _tiles(List<SourceEntry> entries, MediaKindDto kind) {
    return [
      for (final entry in entries)
        SourceTile(
          key: Key('source-${entry.status.id}'),
          label: sourceLabel(kind, entry.number),
          hint: sourceHint(entry.status),
          enabled: entry.status.enabled,
          onChanged: (value) => _toggle(entry.status.id, value),
          checking: _board.checking.contains(entry.status.id),
          ping: _readingOf(entry.status),
        ),
      if (allOff(entries))
        SettingsNote(switch (kind) {
          MediaKindDto.anime =>
            'Semua sumber anime mati, jadi tidak ada yang bisa ditonton.',
          MediaKindDto.manga =>
            'Semua sumber komik mati, jadi tidak ada yang bisa dibaca.',
          MediaKindDto.novel =>
            'Semua sumber novel mati, jadi tidak ada yang bisa dibaca.',
        }, key: Key('all-off-${kind.name}')),
    ];
  }

  PingReading? _readingOf(SourceStatusDto status) {
    final result = _board.results[status.id];
    if (result == null || !status.enabled) return null;
    return pingReading(result);
  }
}
