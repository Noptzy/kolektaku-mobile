import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';

const _barShade = Color(0xE6000000);

String pageCounter(int page, int total) => '${page + 1} / $total';

class ReaderTopBar extends StatelessWidget {
  const ReaderTopBar({
    super.key,
    required this.title,
    required this.onBack,
    this.onChapters,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onChapters;

  @override
  Widget build(BuildContext context) {
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
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ShadTheme.of(context).textTheme.large,
                ),
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

class ReaderBottomBar extends StatelessWidget {
  const ReaderBottomBar({
    super.key,
    required this.page,
    required this.total,
    this.onPrevious,
    this.onNext,
  });

  final int page;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ColoredBox(
      color: _barShade,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sm),
          child: Row(
            children: [
              ShadIconButton.ghost(
                key: const Key('previous-chapter'),
                icon: const Icon(LucideIcons.skipBack),
                onPressed: onPrevious,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    pageCounter(page, total),
                    key: const Key('page-counter'),
                    style: theme.textTheme.large,
                  ),
                ),
              ),
              ShadIconButton.ghost(
                key: const Key('next-chapter'),
                icon: const Icon(LucideIcons.skipForward),
                onPressed: onNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
