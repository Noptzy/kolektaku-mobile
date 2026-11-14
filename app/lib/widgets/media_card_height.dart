import 'package:flutter/widgets.dart';

import '../core/theme/kolektaku_tokens.dart';

double mediaCardHeight(double cardWidth, TextScaler scaler) {
  final text = scaler.scale(2 * 13 * 1.25) + 2 * scaler.scale(12 * 1.3);
  return cardWidth / Sizes.posterAspect +
      Spacing.sm +
      4 +
      text.ceilToDouble() +
      1;
}
