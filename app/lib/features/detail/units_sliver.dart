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
import '../downloads/download_bar.dart';
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
    this.onWrong,
    this.onDownload,
    this.unreleased = false,
    this.releaseLabel,
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
  final VoidCallback? onWrong;
  final ValueChanged<List<UnitDto>>? onDownload;
  final bool unreleased;
  final String? releaseLabel;

  Widget _failure(Object error) {
    if (_isMissing(error)) {
      return StateView.empty(
        key: const Key('units-missing'),
        title: missingUnitsTitle(kind),
        message: missingUnitsMessage(kind),
        actionLabel: onWrong == null ? null : 'Bukan ini?',
        onAction: onWrong,
      );
    }
    if (error is BridgeError) {
      return ErrorStateView(error: error, onRetry: onRetry);
    }
    return StateView.error(
      title: 'Ada yang tidak beres',
      message: 'Daftar belum bisa dimuat.',
      actionLabel: 'Coba lagi',
      onAction: onRetry,
    );
  }

  Widget _empty() {
    if (unreleased) {
      return StateView.empty(
        key: const Key('units-unreleased'),
        title: 'Belum tayang',
        message: releaseLabel == null
            ? 'Episodenya akan muncul setelah judul ini tayang.'
            : 'Episodenya akan muncul setelah tayang, sekitar $releaseLabel.',
      );
    }
    return StateView.empty(
      key: const Key('units-empty'),
      title: 'Belum ada daftar',
      message: missingUnitsMessage(kind),
      actionLabel: onWrong == null ? null : 'Bukan ini?',
      onAction: onWrong,
    );
  }

  @override
  Widget build(BuildContext context) {
    return units.when(
      loading: () => const _Loading(),
      error: (error, stack) =>
          SliverToBoxAdapter(child: _Roomy(child: _failure(error))),
      data: (data) => data.units.isEmpty
          ? SliverToBoxAdapter(child: _Roomy(child: _empty()))
          : _withDownload(
              data.units,
              EpisodeSection(
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
            ),
    );
  }

  Widget _withDownload(List<UnitDto> list, Widget section) {
    final download = onDownload;
    if (download == null) return section;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: DownloadBar(onTap: () => download(list))),
        section,
      ],
    );
  }
}

String missingUnitsMessage(MediaKindDto kind) => switch (kind) {
  MediaKindDto.anime =>
    'Judul ini belum ada di sumber mana pun. Coba "Bukan ini?" atau cek '
        'lagi nanti.',
  MediaKindDto.manga =>
    'Komik ini belum ada di sumber komik yang tersedia. Coba "Bukan ini?" '
        'untuk mencari judulnya sendiri.',
  MediaKindDto.novel =>
    'Novel ini belum ada di sumber novel yang tersedia. Coba "Bukan ini?" '
        'untuk mencari judulnya sendiri.',
};

bool _isMissing(Object error) =>
    error is BridgeError && error.kind == BridgeErrorKind.notFound;

String missingUnitsTitle(MediaKindDto kind) => kind == MediaKindDto.anime
    ? 'Episode tidak ditemukan'
    : 'Chapter tidak ditemukan';

class _Roomy extends StatelessWidget {
  const _Roomy({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 260),
      child: child,
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
