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
    return Row(
      spacing: Spacing.sm,
      children: [
        Flexible(
          child: ShadButton(
            key: const Key('hero-watch'),
            onPressed: onWatch,
            leading: const Icon(LucideIcons.play, size: 16),
            child: Flexible(
              child: Text(
                watchLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        _IconAction(
          key: const Key('hero-save'),
          label: 'Simpan',
          icon: LucideIcons.bookmarkPlus,
          onTap: onSave,
        ),
        if (slide.hasTrailer)
          _IconAction(
            key: const Key('hero-trailer'),
            label: 'Trailer',
            icon: LucideIcons.circlePlay,
            onTap: onTrailer,
          ),
      ],
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      excludeSemantics: true,
      child: ShadIconButton.secondary(
        width: Sizes.touchTarget,
        height: Sizes.touchTarget,
        icon: Icon(icon, size: 20),
        onPressed: onTap,
      ),
    );
  }
}
