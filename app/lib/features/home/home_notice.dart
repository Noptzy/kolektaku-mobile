import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/pesan_error.dart';
import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/cards.dart';

String noticeText(List<NoticeDto> notices) {
  final messages = {for (final notice in notices) pesanError(notice.error)};
  return messages.join(' ');
}

class HomeNotice extends StatelessWidget {
  const HomeNotice({super.key, required this.notices});

  final List<NoticeDto> notices;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          borderRadius: Radii.cardShape,
          border: Border.all(color: theme.colorScheme.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            children: [
              Icon(
                LucideIcons.info,
                size: 18,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(noticeText(notices), style: theme.textTheme.small),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
