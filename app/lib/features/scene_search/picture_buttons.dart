import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';

class PictureButtons extends StatelessWidget {
  const PictureButtons({
    super.key,
    required this.onCamera,
    required this.onFiles,
  });

  final VoidCallback onCamera;
  final VoidCallback onFiles;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: Spacing.md,
      runSpacing: Spacing.md,
      children: [
        ShadButton(
          key: const Key('take-photo'),
          onPressed: onCamera,
          leading: const Icon(LucideIcons.camera, size: 18),
          child: const Text('Ambil foto'),
        ),
        ShadButton.outline(
          key: const Key('pick-file'),
          onPressed: onFiles,
          leading: const Icon(LucideIcons.image, size: 18),
          child: const Text('Pilih dari berkas'),
        ),
      ],
    );
  }
}
