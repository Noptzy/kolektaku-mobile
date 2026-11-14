import 'dart:async';

import 'package:flutter/foundation.dart';

class ControlsVisibility extends ChangeNotifier {
  ControlsVisibility({
    required this.isPlaying,
    this.hideAfter = const Duration(seconds: 3),
  });

  final bool Function() isPlaying;
  final Duration hideAfter;
  Timer? _timer;
  bool _visible = true;
  bool _disposed = false;

  bool get visible => _visible;

  void schedule() {
    _timer?.cancel();
    _timer = Timer(hideAfter, () {
      if (isPlaying()) _set(false);
    });
  }

  void toggle() {
    _set(!_visible);
    if (_visible) schedule();
  }

  void interacted() {
    if (!_visible) _set(true);
    schedule();
  }

  void _set(bool value) {
    if (_disposed || _visible == value) return;
    _visible = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
