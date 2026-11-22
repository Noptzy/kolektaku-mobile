import 'package:flutter/widgets.dart';

import '../core/theme/glass_tokens.dart';

class GlassShadow extends StatelessWidget {
  const GlassShadow({super.key, required this.radius, required this.child});

  final BorderRadius radius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _OutsideShadowPainter(radius), child: child);
  }
}

class _OutsideShadowPainter extends CustomPainter {
  const _OutsideShadowPainter(this.radius);

  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final shape = radius.toRRect(Offset.zero & size);
    final everything = Path()
      ..addRect(Rect.fromLTWH(-200, -200, size.width + 400, size.height + 400));
    final outside = Path.combine(
      PathOperation.difference,
      everything,
      Path()..addRRect(shape),
    );
    canvas
      ..save()
      ..clipPath(outside)
      ..drawRRect(
        shape.shift(const Offset(0, Glass.shadowOffsetY)),
        Paint()
          ..color = Glass.shadowColor
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            Glass.shadowBlur,
          ),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_OutsideShadowPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
