import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'watch_harness.dart';

Future<void> settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 900));

void main() {
  testWidgets('tapping again right after a double tap keeps skipping', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    final zone = find.byKey(const Key('zone-forward'));
    await tester.tap(zone);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(zone);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(zone);
    await tester.pump(const Duration(milliseconds: 50));
    expect(harness.engine.log.where((entry) => entry.startsWith('seek')), [
      'seek 10',
      'seek 20',
    ]);
    expect(find.text('+20 dtk'), findsOneWidget);
    await settle(tester);
  });

  testWidgets('double tapping the middle pauses the video', (tester) async {
    final harness = WatchHarness();
    await harness.open(tester);
    final spot =
        tester.getCenter(find.byKey(const Key('fake-video'))) +
        const Offset(50, 0);
    await tester.tapAt(spot);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(spot);
    await settle(tester);
    expect(harness.engine.log, contains('pause'));
  });

  testWidgets('holding the video plays at 2x and restores the speed', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    final press = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('zone-forward'))),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(harness.engine.log, contains('speed 2.0'));
    final badge = tester.widget<AnimatedOpacity>(
      find.byKey(const Key('hold-badge')),
    );
    expect(badge.opacity, 1);
    await press.up();
    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.engine.log.last, 'speed 1.0');
  });

  testWidgets('dragging the seek bar shows the target time and then seeks', (
    tester,
  ) async {
    final harness = WatchHarness();
    await harness.open(tester);
    harness.engine.emit(position: const Duration(minutes: 1));
    await tester.pump();
    final bar = find.byKey(const Key('seek-bar'));
    final start = tester.getTopLeft(bar) + const Offset(20, 16);
    final drag = await tester.startGesture(start);
    await drag.moveBy(const Offset(200, 0));
    await tester.pump();
    expect(find.byKey(const Key('seek-bubble')), findsOneWidget);
    await drag.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('seek-bubble')), findsNothing);
    expect(
      harness.engine.log.where((entry) => entry.startsWith('seek')),
      hasLength(1),
    );
    await settle(tester);
  });
}
