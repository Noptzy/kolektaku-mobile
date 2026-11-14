import 'package:flutter/widgets.dart';

import '../core/theme/kolektaku_tokens.dart';
import 'media_card_skeleton.dart';

class MediaSkeletonRow extends StatelessWidget {
  const MediaSkeletonRow({super.key, this.columns = 3, this.animate = true});

  final int columns;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.lg,
        Spacing.screenGutter,
        Spacing.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Spacing.md,
        children: [
          for (var i = 0; i < columns; i++)
            Expanded(child: MediaCardSkeleton(animate: animate)),
        ],
      ),
    );
  }
}
