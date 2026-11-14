import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/error.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/state_view.dart';
import 'episode_info_map.dart';
import 'episode_section.dart';

class UnitsSliver extends StatelessWidget {
  const UnitsSliver({
    super.key,
    required this.units,
    required this.view,
    required this.kind,
    required this.progress,
    required this.descending,
    required this.focus,
    required this.onToggleOrder,
    required this.onRetry,
    required this.onPlay,
  });

  final AsyncValue<UnitsDto> units;
  final DetailViewDto view;
  final MediaKindDto kind;
  final Map<double, ProgressDto> progress;
  final bool descending;
  final double? focus;
  final VoidCallback onToggleOrder;
  final VoidCallback onRetry;
  final ValueChanged<UnitDto> onPlay;

  @override
  Widget build(BuildContext context) {
    return units.when(
      loading: () => const _Loading(),
      error: (error, stack) => SliverToBoxAdapter(
        child: SizedBox(
          height: 320,
          child: error is BridgeError
              ? ErrorStateView(error: error, onRetry: onRetry)
              : StateView.error(
                  title: 'Ada yang tidak beres',
                  message: 'Daftar belum bisa dimuat.',
                  actionLabel: 'Coba lagi',
                  onAction: onRetry,
                ),
        ),
      ),
      data: (data) => data.units.isEmpty
          ? const SliverToBoxAdapter(
              child: SizedBox(
                height: 280,
                child: StateView.empty(
                  title: 'Belum ada daftar',
                  message: 'Sumber ini belum punya daftar. Coba "Bukan ini?".',
                ),
              ),
            )
          : EpisodeSection(
              units: data.units,
              kind: kind,
              progress: progress,
              descending: descending,
              focus: focus,
              infos: episodeInfosOf(view),
              art: artOf(view),
              onToggleOrder: onToggleOrder,
              onOpen: onPlay,
            ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      key: const Key('units-loading'),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.screenGutter),
        child: Column(
          spacing: Spacing.md,
          children: [
            for (var i = 0; i < 4; i++)
              const Skeleton(height: 88, radius: Radii.card),
          ],
        ),
      ),
    );
  }
}
