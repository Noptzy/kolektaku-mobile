import 'package:flutter/widgets.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'skeleton.dart';

class MediaCardSkeleton extends StatelessWidget {
  const MediaCardSkeleton({super.key, this.animate = true});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: Sizes.posterAspect,
          child: Skeleton(animate: animate),
        ),
        const SizedBox(height: Spacing.sm),
        Skeleton(height: 12, radius: 4, animate: animate),
        const SizedBox(height: Spacing.xs),
        Skeleton(width: 56, height: 10, radius: 4, animate: animate),
      ],
    );
  }
}
