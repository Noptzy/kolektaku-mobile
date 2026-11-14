import 'package:flutter/widgets.dart';

abstract final class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double screenGutter = 16;
}

abstract final class Radii {
  static const double poster = 12;
  static const double card = 16;
  static const double chip = 999;
  static const double sheet = 20;

  static BorderRadius get posterShape => BorderRadius.circular(poster);
  static BorderRadius get cardShape => BorderRadius.circular(card);
  static BorderRadius get chipShape => BorderRadius.circular(chip);
}

abstract final class Sizes {
  static const double touchTarget = 48;
  static const double posterAspect = 2 / 3;
  static const double heroMaxHeightFraction = 0.55;
  static const double railPosterWidth = 112;
  static const double bottomBarHeight = 64;
}

abstract final class Motion {
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration regular = Duration(milliseconds: 250);
}
