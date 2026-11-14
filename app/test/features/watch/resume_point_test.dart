import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/resume_point.dart';

const _tenMinutes = Duration(minutes: 10);

void main() {
  group('ResumePoint', () {
    test('follows the player when nothing was requested', () {
      final point = ResumePoint();
      expect(
        point.resolve(const Duration(seconds: 42)),
        (const Duration(seconds: 42)),
      );
    });

    test('keeps the requested spot while the player has not reached it', () {
      final point = ResumePoint()..aim(_tenMinutes);
      point.observe(const Duration(seconds: 1));
      expect(point.resolve(Duration.zero), _tenMinutes);
    });

    test('follows the player again once it reached the requested spot', () {
      final point = ResumePoint()..aim(_tenMinutes);
      point.observe(_tenMinutes + const Duration(seconds: 1));
      expect(
        point.resolve(_tenMinutes + const Duration(minutes: 2)),
        (_tenMinutes + const Duration(minutes: 2)),
      );
    });

    test('a backward seek is kept until the player gets there', () {
      final point = ResumePoint()..aim(const Duration(minutes: 5));
      point.observe(const Duration(minutes: 20));
      expect(
        point.resolve(const Duration(minutes: 20)),
        (const Duration(minutes: 5)),
      );
    });

    test('a newer request replaces the older one', () {
      final point = ResumePoint()
        ..aim(_tenMinutes)
        ..aim(const Duration(minutes: 3));
      expect(point.resolve(Duration.zero), const Duration(minutes: 3));
    });

    test('a position inside the tolerance counts as reached', () {
      final point = ResumePoint()..aim(_tenMinutes);
      expect(
        point.resolve(_tenMinutes - const Duration(seconds: 2)),
        (_tenMinutes - const Duration(seconds: 2)),
      );
    });
  });
}
