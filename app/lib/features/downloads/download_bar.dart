import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';

class DownloadBar extends StatelessWidget {
  const DownloadBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.screenGutter,
        Spacing.md,
        Spacing.screenGutter,
        0,
      ),
      child: ShadButton.outline(
        key: const Key('open-download-picker'),
        width: double.infinity,
        onPressed: onTap,
        leading: const Icon(LucideIcons.download, size: 16),
        child: const Text('Unduh episode'),
      ),
    );
  }
}
