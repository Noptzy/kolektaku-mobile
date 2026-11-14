import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'hero_art.dart';
import 'hero_slide.dart';
import 'hero_slide_content.dart';

const _scrimStops = [0.0, 0.4, 0.72, 1.0];
const _scrimAlphas = [0.0, 0.0, 0.8, 0.97];

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
    final scheme = ShadTheme.of(context).colorScheme;
    final inset = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        inset + Spacing.md,
        Spacing.screenGutter,
        Spacing.md,
      ),
      child: ClipRRect(
        key: const Key('hero-card'),
        borderRadius: BorderRadius.circular(Radii.hero),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.card),
            HeroArt(url: slide.imageUrl),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: _scrimStops,
                  colors: [
                    for (final alpha in _scrimAlphas)
                      scheme.background.withValues(alpha: alpha),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: HeroSlideContent(
                  slide: slide,
                  watchLabel: watchLabel,
                  onWatch: onWatch,
                  onSave: onSave,
                  onTrailer: onTrailer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
