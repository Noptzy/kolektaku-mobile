import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_text.dart';

class LimitedDataLabel extends StatelessWidget {
  const LimitedDataLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Text(
      'Data terbatas',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.cardMeta.copyWith(
        color: theme.colorScheme.mutedForeground,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
