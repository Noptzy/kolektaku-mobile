import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_color_scheme.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/poster.dart';
import 'episode_info_map.dart';

const episodeThumbWidth = 128.0;

class EpisodeThumb extends StatelessWidget {
  const EpisodeThumb({
    super.key,
    required this.number,
    required this.url,
    required this.done,
    required this.nowPlaying,
    this.art,
  });

  final double number;
  final String? url;
  final String? art;
  final bool done;
  final bool nowPlaying;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    final own = url != null && url!.isNotEmpty;
    final shown = own ? url : art;
    final hasPicture = shown != null && shown.isNotEmpty;
    return SizedBox(
      width: episodeThumbWidth,
      child: Poster(
        url: shown,
        aspectRatio: 16 / 9,
        radius: Radii.poster - 4,
        placeholder: hasPicture
            ? ColoredBox(color: scheme.popover)
            : NumberTile(number: number),
        overlays: [
          if (hasPicture && !own)
            const Positioned.fill(child: ColoredBox(color: Color(0x73000000))),
          if (hasPicture)
            Positioned(
              left: Spacing.xs,
              bottom: Spacing.xs,
              child: NumberPill(number: number),
            ),
          if (done || nowPlaying)
            Positioned(
              right: Spacing.xs,
              top: Spacing.xs,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.scrim,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    nowPlaying ? LucideIcons.volume2 : LucideIcons.check,
                    size: 14,
                    color: scheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NumberPill extends StatelessWidget {
  const NumberPill({super.key, required this.number});

  final double number;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: episodeThumbWidth - 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.scrim,
          borderRadius: Radii.chipShape,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              numberBadge(number),
              maxLines: 1,
              style: theme.textTheme.badge.copyWith(
                color: theme.colorScheme.foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NumberTile extends StatelessWidget {
  const NumberTile({super.key, required this.number});

  final double number;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: theme.colorScheme.popover,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              numberBadge(number),
              maxLines: 1,
              style: theme.textTheme.sectionTitle.copyWith(
                fontSize: 28,
                color: theme.colorScheme.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
