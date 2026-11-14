import 'package:flutter/widgets.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/hero_carousel.dart';
import '../../widgets/media_card_skeleton.dart';
import '../../widgets/skeleton.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key, this.animate = true});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final height = HeroCarousel.heightFor(MediaQuery.sizeOf(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.xl,
      children: [
        Skeleton(height: height, radius: 0, animate: animate),
        _row(),
        _row(),
      ],
    );
  }

  Widget _row() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: Row(
        spacing: Spacing.md,
        children: [
          for (var i = 0; i < 3; i++)
            Expanded(child: MediaCardSkeleton(animate: animate)),
        ],
      ),
    );
  }
}
