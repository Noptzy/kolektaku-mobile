import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/dates.dart';
import '../../core/labels.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/credits.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/dto/studio.dart';
import '../../widgets/pressable.dart';

String sourceMaterialLabel(String? source) {
  if (source == null) return '';
  return switch (source.toUpperCase()) {
    'MANGA' => 'Komik',
    'LIGHT_NOVEL' => 'Novel ringan',
    'NOVEL' => 'Novel',
    'VISUAL_NOVEL' => 'Visual novel',
    'VIDEO_GAME' => 'Gim',
    'ORIGINAL' => 'Orisinal',
    'WEB_NOVEL' => 'Novel web',
    'ANIME' => 'Anime',
    'OTHER' => 'Lainnya',
    _ => source,
  };
}

String seasonLabel(String? season) {
  if (season == null) return '';
  return switch (season.toUpperCase()) {
    'WINTER' => 'Musim dingin',
    'SPRING' => 'Musim semi',
    'SUMMER' => 'Musim panas',
    'FALL' => 'Musim gugur',
    _ => season,
  };
}

List<(String, String)> infoRows(MediaDetailDto detail, MediaKindDto kind) {
  final summary = detail.summary;
  final airing = detail.nextAiring;
  final rows = <(String, String)>[
    ('Format', formatLabel(summary.format) ?? ''),
    ('Status', statusLabel(summary.status, kind) ?? ''),
    ('Studio', detail.studios.map((studio) => studio.name).join(', ')),
    ('Musim', seasonLabel(detail.season)),
    ('Mulai', formatDate(detail.startDate) ?? ''),
    ('Selesai', formatDate(detail.endDate) ?? ''),
    (
      'Durasi',
      detail.durationMinutes == null ? '' : '${detail.durationMinutes} menit',
    ),
    ('Sumber cerita', sourceMaterialLabel(detail.source)),
    ('Skor', summary.score == null ? '' : summary.score!.toStringAsFixed(1)),
    if (airing != null)
      (
        'Tayang berikutnya',
        'Episode ${airing.episode}, ${formatAiring(airing.airingAtSecs)}',
      ),
  ];
  return rows.where((row) => row.$2.isNotEmpty).toList();
}

List<(String, String)> siteInfoRows(SiteDetailDto site) {
  final rows = <(String, String)>[
    ('Tipe', site.typeText ?? ''),
    ('Tahun', site.year?.toString() ?? ''),
    ('Asal', site.origin ?? ''),
    ('Terbaru', site.latestLabel ?? ''),
  ];
  return rows.where((row) => row.$2.isNotEmpty).toList();
}

const studioLabel = 'Studio';
const _rowHeight = Sizes.touchTarget - Spacing.sm;

class InfoSection extends StatelessWidget {
  const InfoSection({
    super.key,
    required this.rows,
    this.actions = const {},
    this.studios = const [],
    this.onStudio,
  });

  final List<(String, String)> rows;
  final Map<String, VoidCallback> actions;
  final List<StudioRefDto> studios;
  final ValueChanged<StudioRefDto>? onStudio;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    if (rows.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Text(
            'Info lengkap tidak tersedia untuk judul ini.',
            style: theme.textTheme.muted,
          ),
        ),
      );
    }
    return SliverList.builder(
      itemCount: rows.length,
      itemBuilder: (context, index) => _row(context, rows[index]),
    );
  }

  Widget _row(BuildContext context, (String, String) row) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            height: _rowHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(row.$1, style: theme.textTheme.muted),
            ),
          ),
          Expanded(child: _value(context, row)),
        ],
      ),
    );
  }

  Widget _value(BuildContext context, (String, String) row) {
    final theme = ShadTheme.of(context);
    final onStudioTap = onStudio;
    if (row.$1 == studioLabel && studios.isNotEmpty && onStudioTap != null) {
      return Wrap(
        spacing: Spacing.md,
        children: [
          for (final studio in studios)
            _Link(
              key: Key('info-studio-${studio.name}'),
              text: studio.name,
              onTap: () => onStudioTap(studio),
            ),
        ],
      );
    }
    final action = actions[row.$1];
    if (action != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: _Link(key: Key('info-${row.$1}'), text: row.$2, onTap: action),
      );
    }
    return SizedBox(
      height: _rowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(row.$2, style: theme.textTheme.p),
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Pressable(
      onTap: onTap,
      label: text,
      minSize: _rowHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: Spacing.xs,
        children: [
          Flexible(
            child: Text(
              text,
              style: theme.textTheme.p.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
