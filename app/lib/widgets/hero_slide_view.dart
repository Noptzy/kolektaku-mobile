import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_color_scheme.dart';
import '../core/theme/kolektaku_text.dart';
import '../core/theme/kolektaku_tokens.dart';
import 'hero_slide.dart';
import 'poster.dart';
import 'score_badge.dart';

class HeroSlideView extends StatelessWidget {
  const HeroSlideView({
    super.key,
    required this.slide,
    this.onWatch,
    this.onSave,
    this.onTrailer,
    this.watchLabel = 'Tonton',
  });

  final String watchLabel;
  final HeroSlide slide;
  final VoidCallback? onWatch;
  final VoidCallback? onSave;
  final VoidCallback? onTrailer;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Poster(url: slide.imageUrl, aspectRatio: 1, radius: 0),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.3, 0.75, 1],
              colors: [
                const Color(0x00000000),
                theme.colorScheme.scrim,
                theme.colorScheme.background,
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.screenGutter,
            0,
            Spacing.screenGutter,
            Spacing.lg,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                slide.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.heroTitle,
              ),
              const SizedBox(height: Spacing.sm),
              _infoRow(theme),
              const SizedBox(height: Spacing.md),
              _actions(),
            ],
          ),
        ),
      ],
    );
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
        ShadButton.outline(
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
