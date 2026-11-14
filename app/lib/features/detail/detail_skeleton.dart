import 'package:flutter/widgets.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/skeleton.dart';

class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key, this.animate = true});

  final bool animate;

  Widget _bar({double? width, double height = 14}) =>
      Skeleton(width: width, height: height, radius: 4, animate: animate);

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
            spacing: Spacing.lg,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.md,
                children: [
                  Skeleton(
                    width: 104,
                    height: 150,
                    radius: Radii.poster,
                    animate: animate,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: Spacing.sm,
                      children: [
                        _bar(height: 22),
                        _bar(width: 140),
                        _bar(width: 96),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                spacing: Spacing.sm,
                children: [
                  for (var i = 0; i < 3; i++)
                    Skeleton(
                      width: 72,
                      height: 28,
                      radius: Radii.chip,
                      animate: animate,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.sm,
                children: [_bar(), _bar(), _bar(width: 220)],
              ),
              Row(
                spacing: Spacing.sm,
                children: [
                  for (var i = 0; i < 2; i++)
                    Skeleton(
                      width: 112,
                      height: 40,
                      radius: Radii.poster,
                      animate: animate,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
