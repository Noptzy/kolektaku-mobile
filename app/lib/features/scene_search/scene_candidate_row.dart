import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/scene.dart';
import '../../widgets/poster.dart';
import '../../widgets/pressable.dart';
import 'scene_format.dart';

class SceneCandidateRow extends StatelessWidget {
  const SceneCandidateRow({
    super.key,
    required this.match,
    required this.onTap,
    this.best = false,
  });

  final SceneMatchDto match;
  final VoidCallback onTap;
  final bool best;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.screenGutter,
        vertical: Spacing.xs,
      ),
      child: Pressable(
        onTap: onTap,
        minSize: Sizes.touchTarget,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.card,
            borderRadius: Radii.cardShape,
            border: Border.all(
              color: best ? scheme.primary : scheme.border,
              width: best ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              spacing: Spacing.md,
              children: [
                SizedBox(
                  width: 120,
                  child: Poster(
                    url: match.previewImageUrl,
                    aspectRatio: 16 / 9,
                    radius: 8,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Spacing.xs,
                    children: [
                      Text(
                        match.title ?? 'Judul belum diketahui',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(episodeMoment(match), style: theme.textTheme.muted),
                    ],
                  ),
                ),
                ShadBadge.secondary(
                  child: Text(similarityLabel(match.similarity)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
