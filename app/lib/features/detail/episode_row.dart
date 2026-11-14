import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/episodes.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../widgets/pressable.dart';
import '../home/resume_card.dart';
import 'episode_info_map.dart';
import 'episode_thumb.dart';

const episodeRowHeight = 96.0;

class EpisodeRow extends StatelessWidget {
  const EpisodeRow({
    super.key,
    required this.unit,
    required this.kind,
    required this.onTap,
    this.info,
    this.progress,
    this.highlighted = false,
    this.nowPlaying = false,
    this.art,
  });

  final UnitDto unit;
  final MediaKindDto kind;
  final VoidCallback onTap;
  final EpisodeInfoDto? info;
  final ProgressDto? progress;
  final bool highlighted;
  final bool nowPlaying;
  final String? art;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    final fraction = progress == null ? null : resumeFraction(progress!);
    final done = progress?.completed ?? false;
    final subtitle = rowSubtitle(unit, info, kind);
    final emphasised = highlighted || nowPlaying;
    return SizedBox(
      height: episodeRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.screenGutter,
          vertical: Spacing.xs,
        ),
        child: Pressable(
          onTap: onTap,
          label: rowTitle(unit, info, kind),
          minSize: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.card,
              borderRadius: Radii.cardShape,
              border: Border.all(
                color: emphasised ? scheme.primary : scheme.border,
                width: emphasised ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Row(
                spacing: Spacing.md,
                children: [
                  EpisodeThumb(
                    number: unit.number,
                    url: info?.thumbnailUrl,
                    art: art,
                    done: done,
                    nowPlaying: nowPlaying,
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Spacing.xs,
                      children: [
                        Text(
                          rowTitle(unit, info, kind),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.cardTitle.copyWith(
                            fontSize: 14,
                            color: done
                                ? scheme.mutedForeground
                                : scheme.foreground,
                          ),
                        ),
                        if (subtitle != null || nowPlaying)
                          Text(
                            nowPlaying ? 'Sedang diputar' : subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.cardMeta.copyWith(
                              color: nowPlaying
                                  ? scheme.primary
                                  : scheme.mutedForeground,
                            ),
                          ),
                        if (fraction != null && !done)
                          ShadProgress(value: fraction, minHeight: 3),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
