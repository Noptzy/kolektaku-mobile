import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_text.dart';
import '../../core/theme/kolektaku_tokens.dart';

class WatchSectionHeading extends StatelessWidget {
  const WatchSectionHeading({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.lg,
        Spacing.screenGutter,
        Spacing.sm,
      ),
      child: Text(text, style: theme.textTheme.sectionTitle),
    );
  }
}
