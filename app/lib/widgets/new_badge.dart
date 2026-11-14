import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_color_scheme.dart';
import '../core/theme/kolektaku_text.dart';

class NewBadge extends StatelessWidget {
  const NewBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadBadge(
      backgroundColor: theme.colorScheme.favorite,
      foregroundColor: theme.colorScheme.foreground,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Text('Baru', style: theme.textTheme.badge),
    );
  }
}
