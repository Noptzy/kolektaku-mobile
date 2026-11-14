import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';
import '../core/theme/kolektaku_tokens.dart';
import 'hero_backdrop.dart';
import 'hero_slide.dart';
import 'poster.dart';
import 'score_badge.dart';

const heroSynopsisLines = 6;
const _posterShare = 0.3;
const _posterMaxWidth = 130.0;

double heroPosterWidth(double screenWidth) =>
    (screenWidth * _posterShare).clamp(0.0, _posterMaxWidth);

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
    final screen = MediaQuery.sizeOf(context);
    final inset = MediaQuery.paddingOf(context).top;
    return Stack(
      fit: StackFit.expand,
      children: [
        HeroBackdrop(url: slide.imageUrl),
        Padding(
          padding: EdgeInsets.fromLTRB(
            Spacing.screenGutter,
            inset + Spacing.lg,
            Spacing.screenGutter,
            Spacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: heroPosterWidth(screen.width),
                    child: _poster(),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(child: _headline(theme)),
                ],
              ),
              ..._synopsis(theme),
              const Spacer(),
              _actions(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _poster() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.poster),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Poster(url: slide.imageUrl),
    );
  }

  Widget _headline(ShadThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          slide.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.heroTitle,
        ),
        const SizedBox(height: Spacing.sm),
        _infoRow(theme),
      ],
    );
  }

  List<Widget> _synopsis(ShadThemeData theme) {
    final text = slide.synopsis;
    if (text == null || text.isEmpty) return const [];
    return [
      const SizedBox(height: Spacing.md),
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
