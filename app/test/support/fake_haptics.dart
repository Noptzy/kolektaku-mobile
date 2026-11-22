import 'package:kolektaku/platform/haptics.dart';

class FakeHaptics implements Haptics {
  int selections = 0;
  int lights = 0;

  @override
  void selection() => selections++;

  @override
  void light() => lights++;
}
