import 'dart:async';

import 'package:flutter/foundation.dart';

class AutoNext extends ChangeNotifier {
  AutoNext({required this.onElapsed, this.delay = const Duration(seconds: 5)});

  final VoidCallback onElapsed;
  final Duration delay;
  Timer? _timer;
  int _remaining = 0;
  bool _disposed = false;

  bool get active => _timer != null;

  int get remaining => _remaining;

  void start() {
    _stop();
    _remaining = delay.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remaining--;
      if (_remaining <= 0) {
        _stop();
        _notify();
        onElapsed();
      } else {
        _notify();
      }
    });
    _notify();
  }

  void cancel() {
    if (!active) return;
    _stop();
    _notify();
  }

  void now() {
    cancel();
    onElapsed();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _remaining = 0;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
