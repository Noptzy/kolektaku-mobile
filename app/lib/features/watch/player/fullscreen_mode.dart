import 'package:flutter/services.dart';

abstract class FullscreenMode {
  Future<void> enter();

  Future<void> exit();
}

class SystemFullscreenMode implements FullscreenMode {
  const SystemFullscreenMode();

  @override
  Future<void> enter() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Future<void> exit() async {
    await SystemChrome.setPreferredOrientations(const []);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}
