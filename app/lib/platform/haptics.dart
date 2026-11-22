import 'package:flutter/services.dart';

abstract interface class Haptics {
  void selection();

  void light();
}

class DeviceHaptics implements Haptics {
  const DeviceHaptics();

  @override
  void selection() => HapticFeedback.selectionClick();

  @override
  void light() => HapticFeedback.lightImpact();
}
