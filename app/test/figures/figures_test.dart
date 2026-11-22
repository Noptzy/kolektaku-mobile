import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/hairline/brush.dart';
import 'package:kolektaku/figures/gulungan.dart';
import 'package:kolektaku/figures/lupa.dart';
import 'package:kolektaku/figures/tumpuk.dart';

const _palette = HairlinePalette(
  plate: Color(0xFF0E0E12),
  hi: Color(0xFFF5B82E),
  edge: Color(0xFF6A6C74),
  mid: Color(0xFF4A4A52),
  lo: Color(0xFF30303A),
);

void _draw(HairlineFigure figure, double nowMs) {
  final recorder = PictureRecorder();
  figure.paint(HairlineBrush(Canvas(recorder), _palette, 1), nowMs);
  recorder.endRecording().dispose();
}

void main() {
  group('Gulungan', () {
    test('paints at any time without trouble', () {
      final reel = Gulungan();
      for (var now = 0.0; now < 20000; now += 333) {
        _draw(reel, now);
      }
    });

    test('turns at its rate and does not jump when time repeats', () {
      final reel = Gulungan(rate: 2);
      _draw(reel, 0);
      final start = reel.turn;
      _draw(reel, 1000);
      expect(reel.turn - start, closeTo(2, 1e-9));
      _draw(reel, 1000);
      expect(reel.turn - start, closeTo(2, 1e-9));
    });

    test('never turns backwards if the clock does', () {
      final reel = Gulungan();
      _draw(reel, 5000);
      final turn = reel.turn;
      _draw(reel, 1000);
      expect(reel.turn, turn);
    });

    test('a slower rate turns less over the same time', () {
      final slow = Gulungan(rate: 0.5);
      final fast = Gulungan(rate: 2);
      for (final reel in [slow, fast]) {
        _draw(reel, 0);
        _draw(reel, 2000);
      }
      expect(fast.turn, greaterThan(slow.turn));
    });
  });

  group('Tumpuk stackAt', () {
    test('has four plates and exactly one is moving', () {
      for (final now in [0.0, 300, 700, 1200, 2000, 2500, 4000]) {
        final rows = stackAt(now.toDouble(), 700);
        expect(rows, hasLength(4));
        expect(rows.where((row) => row.moving), hasLength(1), reason: '$now');
        expect(rows.map((row) => row.plate).toSet(), hasLength(4));
      }
    });

    test('is drawn from the lowest plate to the highest', () {
      for (final now in [0.0, 400, 900, 1500, 2000]) {
        final rows = stackAt(now.toDouble(), 700);
        for (var i = 1; i < rows.length; i++) {
          expect(rows[i].z, greaterThanOrEqualTo(rows[i - 1].z));
        }
      }
    });

    test(
      'the bottom plate slides out first, then rises, then lands on top',
      () {
        final out = stackAt(700 * 0.99, 700).firstWhere((row) => row.moving);
        expect(out.x, greaterThan(40));
        expect(out.z, lessThan(1));
        final up = stackAt(700 * 1.99, 700).firstWhere((row) => row.moving);
        expect(up.x, closeTo(54, 1));
        expect(up.z, greaterThan(20));
        final done = stackAt(700 * 2.999, 700).firstWhere((row) => row.moving);
        expect(done.x, closeTo(0, 0.5));
        final others = stackAt(700 * 2.999, 700).where((row) => !row.moving);
        expect(
          done.z,
          greaterThan(
            others.map((row) => row.z).reduce((a, b) => a > b ? a : b),
          ),
        );
      },
    );

    test(
      'each plate takes its turn and the pattern repeats after four turns',
      () {
        final movers = <int>[];
        for (var turn = 0; turn < 4; turn++) {
          final now = 700.0 * 3 * turn + 10;
          movers.add(stackAt(now, 700).firstWhere((row) => row.moving).plate);
        }
        expect(movers.toSet(), hasLength(4));
        final again = stackAt(
          700.0 * 3 * 4 + 10,
          700,
        ).firstWhere((row) => row.moving).plate;
        expect(again, movers.first);
      },
    );

    test('a longer beat stretches the whole loop', () {
      final quick = stackAt(900, 450).firstWhere((row) => row.moving);
      final slow = stackAt(900, 900).firstWhere((row) => row.moving);
      expect(quick.z, isNot(slow.z));
    });
  });

  group('Tumpuk', () {
    test('paints at any time without trouble', () {
      final stack = Tumpuk();
      for (var now = 0.0; now < 20000; now += 217) {
        _draw(stack, now);
      }
    });
  });

  group('Lupa', () {
    test('paints at any time without trouble', () {
      final lupa = Lupa();
      for (var now = 0.0; now < 30000; now += 251) {
        _draw(lupa, now);
      }
    });

    test('starts over the first card of its search with that card lit', () {
      final lupa = Lupa();
      _draw(lupa, 0);
      expect(lupa.loupeCard, hopOrder.first);
      expect(lupa.litCard(0), hopOrder.first);
    });

    test(
      'hops to the next card on each beat and lights it only after a pause',
      () {
        final lupa = Lupa();
        _draw(lupa, 0);
        _draw(lupa, 1500);
        expect(lupa.loupeCard, hopOrder[1]);
        expect(lupa.litCard(1500), isNull);
        expect(lupa.litCard(1500 + 300), isNull);
        expect(lupa.litCard(1500 + 600), hopOrder[1]);
      },
    );

    test('visits every card of the rack in six beats', () {
      final lupa = Lupa();
      final seen = <int>{};
      for (var beat = 0; beat < 6; beat++) {
        _draw(lupa, beat * 1500.0);
        seen.add(lupa.loupeCard);
      }
      expect(seen, hasLength(6));
    });

    test('a shorter hop makes the loupe move sooner', () {
      final quick = Lupa(hopMs: 600);
      _draw(quick, 0);
      _draw(quick, 600);
      expect(quick.loupeCard, hopOrder[1]);
    });

    test('painting the same moment twice does not hop again', () {
      final lupa = Lupa();
      _draw(lupa, 0);
      _draw(lupa, 1500);
      _draw(lupa, 1500);
      expect(lupa.loupeCard, hopOrder[1]);
    });

    test('starting in the middle of the clock begins on the matching card', () {
      final lupa = Lupa();
      _draw(lupa, 1500.0 * 3 + 10);
      expect(lupa.loupeCard, hopOrder[3]);
    });
  });
}
