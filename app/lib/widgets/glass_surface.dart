import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import '../core/theme/glass_tokens.dart';
import 'glass_budget.dart';
import 'glass_shadow.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({super.key, required this.radius, required this.child});

  final BorderRadius radius;
  final Widget child;

  bool _blurred(BuildContext context) {
    if (MediaQuery.highContrastOf(context)) return false;
    return !GlassBudgetScope.trippedOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: Glass.rim);
    final inner = _blurred(context)
        ? DecoratedBox(
            decoration: BoxDecoration(borderRadius: radius, border: border),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: Glass.blurSigma,
                  sigmaY: Glass.blurSigma,
                ),
                child: ColoredBox(color: Glass.tint, child: child),
              ),
            ),
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: Glass.solid,
              borderRadius: radius,
              border: border,
            ),
            child: child,
          );
    return GlassShadow(radius: radius, child: inner);
  }
}
