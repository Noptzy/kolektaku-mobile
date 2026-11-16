import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../widgets/pressable.dart';

Future<void> showIllustration(BuildContext context, ImageProvider image) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, animation, secondary) =>
          IllustrationPage(image: image),
      transitionsBuilder: (context, animation, secondary, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

class IllustrationPage extends StatelessWidget {
  const IllustrationPage({super.key, required this.image});

  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF000000),
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: Image(
                key: const Key('illustration-large'),
                image: image,
                fit: BoxFit.contain,
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: Pressable(
                  key: const Key('illustration-close'),
                  onTap: () => Navigator.of(context).maybePop(),
                  label: 'Tutup gambar',
                  minSize: Sizes.touchTarget,
                  child: const Center(
                    child: Icon(
                      LucideIcons.x,
                      size: 24,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
