import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';

const _barShade = Color(0xE6000000);

class NovelTopBar extends StatelessWidget {
  const NovelTopBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onLook,
    this.caption,
    this.onChapters,
    this.onToggleOriginal,
    this.showingOriginal = false,
  });

  final String title;
  final String? caption;
  final VoidCallback onBack;
  final VoidCallback onLook;
  final VoidCallback? onChapters;
  final VoidCallback? onToggleOriginal;
  final bool showingOriginal;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: _barShade,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Row(
            children: [
              ShadIconButton.ghost(
                key: const Key('back'),
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: onBack,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.large,
                    ),
                    if (caption != null)
                      Text(
                        caption!,
                        key: const Key('translation-caption'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.muted,
                      ),
                  ],
                ),
              ),
              if (onToggleOriginal != null)
                ShadIconButton.ghost(
                  key: const Key('toggle-original'),
                  icon: const Icon(LucideIcons.languages),
                  onPressed: onToggleOriginal,
                ),
              ShadIconButton.ghost(
                key: const Key('open-look'),
                icon: const Icon(LucideIcons.type),
                onPressed: onLook,
              ),
              if (onChapters != null)
                ShadIconButton.ghost(
                  key: const Key('chapters'),
                  icon: const Icon(LucideIcons.listOrdered),
                  onPressed: onChapters,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
