import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/start_guard.dart';

const _start = Duration(minutes: 10);

Future<int> run({
  required Duration Function() position,
  required List<Duration> seeks,
  bool Function()? active,
  Duration start = _start,
}) {
  return holdStart(
    start: start,
    position: position,
    seek: (target) async => seeks.add(target),
    active: active ?? () => true,
    poll: const Duration(milliseconds: 1),
    pollsPerAttempt: 3,
  );
}

void main() {
  group('holdStart', () {
    test('does nothing when the player already sits at the start', () async {
      final seeks = <Duration>[];
      final reseeks = await run(position: () => _start, seeks: seeks);
      expect(reseeks, 0);
      expect(seeks, isEmpty);
    });

    test('accepts a position slightly before the start', () async {
      final seeks = <Duration>[];
      final reseeks = await run(
        position: () => _start - const Duration(seconds: 2),
        seeks: seeks,
      );
      expect(reseeks, 0);
      expect(seeks, isEmpty);
    });

    test('seeks again when the player restarted from the beginning', () async {
      final seeks = <Duration>[];
      var current = const Duration(seconds: 1);
      final reseeks = await holdStart(
        start: _start,
        position: () => current,
        seek: (target) async {
          seeks.add(target);
          current = target;
        },
        active: () => true,
        poll: const Duration(milliseconds: 1),
        pollsPerAttempt: 3,
      );
      expect(reseeks, 1);
      expect(seeks, [_start]);
    });

    test('gives up after the allowed number of attempts', () async {
      final seeks = <Duration>[];
      final reseeks = await run(
        position: () => const Duration(seconds: 1),
        seeks: seeks,
      );
      expect(reseeks, 3);
      expect(seeks, [_start, _start, _start]);
    });

    test('stops quietly once the player is no longer active', () async {
      final seeks = <Duration>[];
      final reseeks = await run(
        position: () => Duration.zero,
        seeks: seeks,
        active: () => false,
      );
      expect(reseeks, 0);
      expect(seeks, isEmpty);
    });

    test('a start near the beginning needs no guarding', () async {
      final seeks = <Duration>[];
      final reseeks = await run(
        position: () => Duration.zero,
        seeks: seeks,
        start: const Duration(seconds: 2),
      );
      expect(reseeks, 0);
      expect(seeks, isEmpty);
    });

    test('a user seek that flips active stops further re-seeks', () async {
      final seeks = <Duration>[];
      var ticks = 0;
      final reseeks = await run(
        position: () => Duration.zero,
        seeks: seeks,
        active: () => ++ticks < 5,
      );
      expect(reseeks, 1);
      expect(seeks, [_start]);
    });
  });
}
