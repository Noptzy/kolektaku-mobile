import 'package:flutter/widgets.dart';

abstract final class Glass {
  static const double blurSigma = 20;
  static const Color tint = Color(0x991E1E26);
  static const Color solid = Color(0xFF1A1A20);
  static const Color rim = Color(0x14FFFFFF);
  static const Color shadowColor = Color(0x73000000);
  static const double shadowBlur = 14;
  static const double shadowOffsetY = 10;
}

abstract final class DockMetrics {
  static const double height = 64;
  static const double sideInset = 16;
  static const double gapAboveSystem = 12;
  static const double contentGap = 16;
  static const double radius = 32;
  static const double itemPadding = 6;

  static double bottomOffset(double systemBottom) =>
      systemBottom + gapAboveSystem;

  static double clearance(double systemBottom) =>
      bottomOffset(systemBottom) + height + contentGap;
}
