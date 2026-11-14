import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/routes.dart';
import '../core/theme/kolektaku_text.dart';
import '../core/theme/kolektaku_tokens.dart';
import 'pressable.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.sm,
        Spacing.sm,
        Spacing.screenGutter,
        Spacing.sm,
      ),
      child: Row(
        children: [
          Pressable(
            onTap: () =>
                context.canPop() ? context.pop() : context.go(Routes.home),
            label: 'Kembali',
            minSize: Sizes.touchTarget,
            child: Center(
              child: Icon(
                LucideIcons.arrowLeft,
                size: 22,
                color: theme.colorScheme.foreground,
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.sectionTitle,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
