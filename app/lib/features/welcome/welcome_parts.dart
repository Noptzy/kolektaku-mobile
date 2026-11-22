import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';
import 'welcome_copy.dart';

const _logoAsset = 'assets/brand/kolektaku-cat-transparent.png';
const _logoSize = 32.0;

class WelcomeTopBar extends StatelessWidget {
  const WelcomeTopBar({
    super.key,
    required this.visibleSkip,
    required this.onSkip,
  });

  final bool visibleSkip;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      children: [
        Image.asset(_logoAsset, width: _logoSize, height: _logoSize),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            welcomeBrandName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.sectionTitle.copyWith(
              color: theme.colorScheme.foreground,
            ),
          ),
        ),
        IgnorePointer(
          ignoring: !visibleSkip,
          child: AnimatedOpacity(
            opacity: visibleSkip ? 1 : 0,
            duration: Motion.quick,
            child: Pressable(
              key: const Key('welcome-skip'),
              onTap: onSkip,
              label: welcomeSkipLabel,
              minSize: Sizes.touchTarget,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  child: Text(
                    welcomeSkipLabel,
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.foreground.withValues(
                        alpha: 0.85,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class WelcomePageText extends StatelessWidget {
  const WelcomePageText({super.key, required this.page});

  final WelcomePage page;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.md,
                children: [
                  Text(
                    page.title,
                    style: theme.textTheme.heroTitle.copyWith(
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  Text(
                    page.body,
                    style: theme.textTheme.p.copyWith(
                      color: theme.colorScheme.mutedForeground,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
