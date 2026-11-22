import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';

const _fillAlpha = 0.12;
const _ringAlpha = 0.55;
const _badgeSize = 18.0;

String filterButtonLabel(int count) =>
    count == 0 ? 'Filter' : 'Filter ($count)';

class SearchFilterButton extends StatelessWidget {
  const SearchFilterButton({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final active = count > 0;
    return Pressable(
      onTap: onTap,
      label: filterButtonLabel(count),
      minSize: Sizes.touchTarget,
      child: SizedBox.square(
        dimension: Sizes.touchTarget,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: Motion.quick,
              decoration: BoxDecoration(
                color: active
                    ? Color.alphaBlend(
                        scheme.primary.withValues(alpha: _fillAlpha),
                        scheme.card,
                      )
                    : scheme.card,
                borderRadius: BorderRadius.circular(Radii.poster),
                border: Border.all(
                  color: active
                      ? scheme.primary.withValues(alpha: _ringAlpha)
                      : scheme.border,
                ),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.slidersHorizontal,
                  size: 20,
                  color: active
                      ? scheme.primary
                      : scheme.foreground.withValues(alpha: 0.8),
                ),
              ),
            ),
            if (active)
              Positioned(
                top: -6,
                right: -6,
                child: ExcludeSemantics(child: _Badge(count: count)),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.background, width: 2),
      ),
      child: SizedBox.square(
        dimension: _badgeSize,
        child: Center(
          child: Text(
            '$count',
            key: const Key('filter-badge'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: scheme.primaryForeground,
            ),
          ),
        ),
      ),
    );
  }
}
