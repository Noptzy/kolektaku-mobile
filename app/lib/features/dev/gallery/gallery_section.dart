import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../core/theme/kolektaku_text.dart';
import '../../../core/theme/kolektaku_tokens.dart';

class GallerySection extends StatelessWidget {
  const GallerySection({
    super.key,
    required this.title,
    required this.child,
    this.titleInset = 0,
  });

  final String title;
  final Widget child;
  final double titleInset;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: titleInset),
            child: Text(title, style: theme.textTheme.sectionTitle),
          ),
          const SizedBox(height: Spacing.md),
          child,
        ],
      ),
    );
  }
}
