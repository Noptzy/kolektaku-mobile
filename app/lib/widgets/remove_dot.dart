import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../core/theme/kolektaku_color_scheme.dart';
import 'pressable.dart';

class RemoveDot extends StatelessWidget {
  const RemoveDot({super.key, required this.onTap, this.label = 'Hapus'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    return Pressable(
      onTap: onTap,
      label: label,
      minSize: 32,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.scrim,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(LucideIcons.x, size: 14, color: scheme.foreground),
          ),
        ),
      ),
    );
  }
}
