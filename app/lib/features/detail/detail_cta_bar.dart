import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_color_scheme.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';
import 'cta_plan.dart';

class DetailCtaBar extends StatelessWidget {
  const DetailCtaBar({
    super.key,
    required this.plan,
    required this.isFavorite,
    required this.onPlay,
    required this.onFavorite,
  });

  final CtaPlan plan;
  final bool isFavorite;
  final VoidCallback? onPlay;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.background,
        border: Border(top: BorderSide(color: scheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.screenGutter,
            vertical: Spacing.md,
          ),
          child: Row(
            spacing: Spacing.md,
            children: [
              Expanded(
                child: ShadButton(
                  onPressed: plan.enabled ? onPlay : null,
                  size: ShadButtonSize.lg,
                  leading: Icon(
                    plan.enabled ? LucideIcons.play : LucideIcons.circleOff,
                    size: 18,
                  ),
                  child: Flexible(
                    child: Text(
                      plan.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Pressable(
                onTap: onFavorite,
                label: isFavorite ? 'Hapus dari favorit' : 'Simpan ke favorit',
                selected: isFavorite,
                minSize: Sizes.touchTarget,
                child: Center(
                  child: Icon(
                    LucideIcons.heart,
                    size: 26,
                    color: isFavorite ? scheme.favorite : scheme.foreground,
                    fill: isFavorite ? 1 : 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
