class ResumePoint {
  ResumePoint({this.tolerance = const Duration(seconds: 3)});

  final Duration tolerance;
  Duration? _target;

  void aim(Duration target) => _target = target;

  void observe(Duration position) {
    final target = _target;
    if (target != null && _near(position, target)) _target = null;
  }

  Duration resolve(Duration position) {
    final target = _target;
    if (target == null || _near(position, target)) return position;
    return target;
  }

  bool _near(Duration a, Duration b) => (a - b).abs() <= tolerance;
}
