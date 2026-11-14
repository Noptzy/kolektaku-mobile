import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_tokens.dart';

class TabTitle extends StatelessWidget {
  const TabTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.md,
        Spacing.screenGutter,
        Spacing.sm,
      ),
      child: Text(
        title,
        style: theme.textTheme.h3.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
