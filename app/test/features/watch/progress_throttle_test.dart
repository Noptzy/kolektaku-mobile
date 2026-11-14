import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/progress_throttle.dart';

void main() {
  test('the first position always passes and then every five seconds', () {
    final throttle = ProgressThrottle();
    expect(throttle.shouldReport(const Duration(seconds: 2)), isTrue);
    expect(throttle.shouldReport(const Duration(seconds: 6)), isFalse);
    expect(throttle.shouldReport(const Duration(seconds: 7)), isTrue);
  });

  test('jumping backwards by more than the interval also reports', () {
    final throttle = ProgressThrottle();
    throttle.shouldReport(const Duration(seconds: 100));
    expect(throttle.shouldReport(const Duration(seconds: 10)), isTrue);
  });

  test('forgetting starts over', () {
    final throttle = ProgressThrottle();
    throttle.shouldReport(const Duration(seconds: 1));
    throttle.forget();
    expect(throttle.shouldReport(const Duration(seconds: 1)), isTrue);
  });
}
