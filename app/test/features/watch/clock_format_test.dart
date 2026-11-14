import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/clock_format.dart';

void main() {
  test('minutes and seconds are zero padded', () {
    expect(formatClock(const Duration(seconds: 5)), '00:05');
    expect(formatClock(const Duration(minutes: 4, seconds: 36)), '04:36');
  });

  test('an hour or more adds the hours', () {
    expect(
      formatClock(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });

  test('negative durations show as zero', () {
    expect(formatClock(const Duration(seconds: -4)), '00:00');
  });
}
