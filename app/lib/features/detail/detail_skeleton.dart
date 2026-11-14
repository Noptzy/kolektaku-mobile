import 'package:flutter/widgets.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/skeleton.dart';

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key, this.animate = true});

  final bool animate;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.lg,
      children: [
        Skeleton(height: width / 1.6, radius: 0, animate: animate),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spacing.md,
            children: [
              Skeleton(height: 22, radius: 4, animate: animate),
              Skeleton(width: 160, height: 14, radius: 4, animate: animate),
              Skeleton(height: 14, radius: 4, animate: animate),
              Skeleton(height: 14, radius: 4, animate: animate),
              Skeleton(width: 220, height: 14, radius: 4, animate: animate),
            ],
          ),
        ),
      ],
    );
  }
}
