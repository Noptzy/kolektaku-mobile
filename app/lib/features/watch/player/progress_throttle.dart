class ProgressThrottle {
  ProgressThrottle({this.every = const Duration(seconds: 5)});

  final Duration every;
  Duration? _last;

  bool shouldReport(Duration position) {
    final last = _last;
    if (last != null && (position - last).abs() < every) return false;
    _last = position;
    return true;
  }

  void forget() => _last = null;
}
