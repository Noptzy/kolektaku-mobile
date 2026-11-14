import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import 'scene_format.dart';

class QuotaNote extends StatelessWidget {
  const QuotaNote({super.key, required this.left});

  final int? left;

  @override
  Widget build(BuildContext context) {
    final remaining = left;
    if (remaining == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(Spacing.screenGutter),
      child: Text(
        quotaLabel(remaining),
        style: ShadTheme.of(context).textTheme.muted,
      ),
    );
  }
}
