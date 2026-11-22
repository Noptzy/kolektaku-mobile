import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/haptics_provider.dart';
import 'package:kolektaku/features/collection/history_swipe.dart';

import '../../support/fake_haptics.dart';
import '../../widgets/widget_harness.dart';

const _rowWidth = 358.0;

Future<({FakeHaptics haptics, List<String> removed})> _show(
  WidgetTester tester,
) async {
  final haptics = FakeHaptics();
  final removed = <String>[];
  await pumpAtSize(
    tester,
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: _rowWidth,
        child: ProviderScope(
          overrides: [hapticsProvider.overrideWithValue(haptics)],
          child: HistorySwipe(
            id: 'a',
            onRemoved: () => removed.add('a'),
            child: const SizedBox(height: 66, child: Text('riwayat')),
          ),
        ),
      ),
    ),
  );
  return (haptics: haptics, removed: removed);
}

void main() {
  group('swipeFraction', () {
    test('turns 104 dp into a share of the row width', () {
      expect(swipeFraction(358), closeTo(104 / 358, 0.0001));
      expect(swipeFraction(208), closeTo(0.5, 0.0001));
    });

    test('never goes below 5% or above 90%', () {
      expect(swipeFraction(100000), 0.05);
      expect(swipeFraction(50), 0.9);
    });

    test('an unknown width falls back to a sane share', () {
      expect(swipeFraction(double.infinity), 0.4);
      expect(swipeFraction(0), 0.4);
    });
  });

  group('HistorySwipe haptics', () {
    testWidgets('a short drag that never reaches 104 dp is silent', (
      tester,
    ) async {
      final shown = await _show(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('riwayat')),
      );
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(shown.haptics.selections, 0);
      expect(shown.haptics.lights, 0);
      expect(shown.removed, isEmpty);
    });

    testWidgets('crossing the threshold ticks once per crossing', (
      tester,
    ) async {
      final shown = await _show(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('riwayat')),
      );
      await gesture.moveBy(const Offset(-70, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      expect(shown.haptics.selections, 1);

      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();
      expect(shown.haptics.selections, 1);

      await gesture.moveBy(const Offset(-120, 0));
      await tester.pump();
      expect(shown.haptics.selections, 2);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('swiping right removes it with a tick and a light impact', (
      tester,
    ) async {
      final shown = await _show(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('riwayat')),
      );
      await gesture.moveBy(const Offset(180, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(shown.removed, ['a']);
      expect(shown.haptics.selections, 1);
      expect(shown.haptics.lights, 1);
    });

    testWidgets('swiping left removes it too', (tester) async {
      final shown = await _show(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('riwayat')),
      );
      await gesture.moveBy(const Offset(-180, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(shown.removed, ['a']);
      expect(shown.haptics.lights, 1);
    });
  });
}
