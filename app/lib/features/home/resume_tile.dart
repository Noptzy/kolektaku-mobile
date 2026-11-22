import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/kind_names.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/library.dart';
import '../../widgets/poster.dart';
import '../../widgets/pressable.dart';
import 'resume_card.dart';
import 'resume_labels.dart';

const resumeTileWidth = 304.0;
const _posterWidth = 64.0;
const _playSize = 40.0;
const _padding = 8.0;

double resumeTileHeight(TextScaler scaler) {
  final text =
      scaler.scale(16) +
      scaler.scale(20) +
      scaler.scale(16) +
      scaler.scale(16) +
      3 * Spacing.xs;
  final poster = _posterWidth / Sizes.posterAspect;
  return 2 * _padding + math.max(poster, text.ceilToDouble());
}

String resumeDetail(ProgressDto progress) {
  final unit = resumeMeta(progress.kind, progress.unitNumber);
  final left = remainingLabel(progress);
  return left == null ? unit : '$unit · $left';
}

class ResumeTile extends StatelessWidget {
  const ResumeTile({
    super.key,
    required this.progress,
    required this.onTap,
    this.now,
  });

  final ProgressDto progress;
  final VoidCallback onTap;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return Pressable(
      onTap: onTap,
      label: 'Lanjutkan ${progress.title}, ${resumeDetail(progress)}',
      child: SizedBox(
        width: resumeTileWidth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.card,
            borderRadius: Radii.cardShape,
          ),
          child: Padding(
            padding: const EdgeInsets.all(_padding),
            child: Row(
              spacing: Spacing.md,
              children: [
                SizedBox(
                  width: _posterWidth,
                  child: Poster(url: progress.coverUrl, radius: 10),
                ),
                Expanded(
                  child: _Info(progress: progress, now: now),
                ),
                _PlayButton(
                  color: scheme.primary,
                  icon: scheme.primaryForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.progress, required this.now});

  final ProgressDto progress;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.cardMeta.copyWith(
      color: scheme.mutedForeground,
    );
    final fraction = resumeFraction(progress) ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: Spacing.xs,
      children: [
        Row(
          spacing: Spacing.sm,
          children: [
            _KindBadge(label: kindTitle(progress.kind)),
            Expanded(
              child: Text(
                agoLabel(now ?? DateTime.now(), progress.updatedAtSecs),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
          ],
        ),
        Text(
          progress.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.cardTitle.copyWith(fontSize: 14),
        ),
        Text(
          resumeDetail(progress),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: muted,
        ),
        Row(
          spacing: Spacing.sm,
          children: [
            Expanded(
              child: ShadProgress(
                value: fraction,
                minHeight: 4,
                borderRadius: Radii.chipShape,
                innerBorderRadius: Radii.chipShape,
              ),
            ),
            Text('${percentDone(progress)}%', style: muted),
          ],
        ),
      ],
    );
  }
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
        child: Text(
          label,
          maxLines: 1,
          style: theme.textTheme.badge.copyWith(
            color: theme.colorScheme.foreground.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.color, required this.icon});

  final Color color;
  final Color icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: SizedBox.square(
          dimension: _playSize,
          child: Icon(LucideIcons.play, size: 18, color: icon),
        ),
      ),
    );
  }
}
