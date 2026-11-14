import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';
import '../core/theme/kolektaku_tokens.dart';
import 'hero_slide.dart';
import 'score_badge.dart';

const heroSynopsisLines = 3;

class HeroSlideContent extends StatelessWidget {
  const HeroSlideContent({
    super.key,
    required this.slide,
    required this.watchLabel,
    this.onWatch,
    this.onSave,
    this.onTrailer,
  });

  final HeroSlide slide;
  final String watchLabel;
  final VoidCallback? onWatch;
  final VoidCallback? onSave;
  final VoidCallback? onTrailer;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ..._label(theme),
        Text(
          slide.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.heroTitle,
        ),
        const SizedBox(height: Spacing.sm),
        _infoRow(theme),
        ..._synopsis(theme),
        const SizedBox(height: Spacing.md),
        _actions(),
      ],
    );
  }

  List<Widget> _label(ShadThemeData theme) {
    final text = slide.label;
    if (text == null || text.isEmpty) return const [];
    return [
      Text(
        text,
        key: const Key('hero-label'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.small.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: Spacing.xs),
    ];
  }

  List<Widget> _synopsis(ShadThemeData theme) {
    final text = slide.synopsis;
    if (text == null || text.isEmpty) return const [];
    return [
      const SizedBox(height: Spacing.sm),
      Flexible(
        child: ClipRect(
          child: Text(
            text,
            key: const Key('hero-synopsis'),
            maxLines: heroSynopsisLines,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.foreground.withValues(alpha: 0.78),
              height: 1.4,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _infoRow(ShadThemeData theme) {
    final score = slide.score;
    return Row(
      children: [
        if (score != null) ...[
          ScoreBadge(score: score),
          const SizedBox(width: Spacing.sm),
        ],
        Flexible(
          child: Text(
            slide.meta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        ShadButton(
          onPressed: onWatch,
          leading: const Icon(LucideIcons.play, size: 16),
          child: Text(watchLabel),
        ),
        ShadButton.secondary(
          onPressed: onSave,
          leading: const Icon(LucideIcons.plus, size: 16),
          child: const Text('Simpan'),
        ),
        if (slide.hasTrailer)
          ShadButton.outline(
            onPressed: onTrailer,
            child: const Text('Trailer'),
          ),
      ],
    );
  }
}
