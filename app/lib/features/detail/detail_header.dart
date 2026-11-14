import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/routes.dart';
import '../../core/theme/kolektaku_color_scheme.dart';
import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/poster.dart';
import '../../widgets/pressable.dart';
import '../../widgets/score_badge.dart';
import 'detail_info.dart';

const _posterWidth = 112.0;
const _overlap = 20.0;

class DetailHeader extends StatelessWidget {
  const DetailHeader({super.key, required this.info});

  final DetailInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final bannerHeight = constraints.maxWidth / 1.6;
        final posterHeight = _posterWidth / Sizes.posterAspect;
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: bannerHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Poster(
                        url: info.bannerUrl ?? info.coverUrl,
                        aspectRatio: 1.6,
                        radius: 0,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0x00000000),
                              theme.colorScheme.background,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: posterHeight - _overlap + Spacing.sm,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.screenGutter + _posterWidth + Spacing.lg,
                      Spacing.sm,
                      Spacing.screenGutter,
                      0,
                    ),
                    child: _Titles(info: info),
                  ),
                ),
              ],
            ),
            Positioned(
              left: Spacing.screenGutter,
              top: bannerHeight - _overlap,
              width: _posterWidth,
              child: Poster(url: info.coverUrl),
            ),
            const Positioned(
              left: Spacing.sm,
              top: Spacing.sm,
              child: _BackButton(),
            ),
          ],
        );
      },
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.info});

  final DetailInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    final score = info.score;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.sectionTitle.copyWith(fontSize: 22),
        ),
        if (info.altTitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              info.altTitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.small.copyWith(color: muted),
            ),
          ),
        if (info.meta.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Text(
              info.meta,
              style: theme.textTheme.small.copyWith(color: muted),
            ),
          ),
        if (score != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ScoreBadge(score: score),
            ),
          ),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Pressable(
      onTap: () => context.canPop() ? context.pop() : context.go(Routes.home),
      label: 'Kembali',
      minSize: Sizes.touchTarget,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.scrim,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.sm),
            child: Icon(
              LucideIcons.arrowLeft,
              size: 22,
              color: scheme.foreground,
            ),
          ),
        ),
      ),
    );
  }
}
