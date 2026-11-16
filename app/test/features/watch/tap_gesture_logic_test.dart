import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/tap_gesture_logic.dart';

class Rig {
  Rig() {
    logic = TapGestureLogic(
      onSingleTap: () => events.add('single'),
      onCenterDouble: () => events.add('center-double'),
      onSkip: (zone, count) => events.add('skip ${zone.name} $count'),
      onSkipEnd: () => events.add('skip-end'),
      onHoldStart: () => events.add('hold-start'),
      onHoldEnd: () => events.add('hold-end'),
    );
  }

  final List<String> events = [];
  late final TapGestureLogic logic;

  void tap(TapZone zone) {
    logic.down(zone, Offset.zero);
    logic.up();
  }
}

Future<void> wait(WidgetTester tester, int millis) =>
    tester.pump(Duration(milliseconds: millis));

void main() {
  testWidgets('one tap toggles the controls only after the double tap window', (
    tester,
  ) async {
    final rig = Rig();
    addTearDown(rig.logic.dispose);
    rig.tap(TapZone.center);
    await wait(tester, 200);
    expect(rig.events, isEmpty);
    await wait(tester, 150);
    expect(rig.events, ['single']);
  });

  testWidgets('two quick taps on a side skip once instead of toggling', (
    tester,
  ) async {
    final rig = Rig();
    addTearDown(rig.logic.dispose);
    rig.tap(TapZone.forward);
    await wait(tester, 100);
    rig.tap(TapZone.forward);
    await wait(tester, 400);
    expect(rig.events, ['skip forward 1']);
  });

  testWidgets('more taps in the same side keep skipping and add up', (
    tester,
  ) async {
    final rig = Rig();
    addTearDown(rig.logic.dispose);
    rig.tap(TapZone.back);
    await wait(tester, 80);
    rig.tap(TapZone.back);
    await wait(tester, 200);
    rig.tap(TapZone.back);
    await wait(tester, 200);
    rig.tap(TapZone.back);
    expect(rig.events, ['skip back 1', 'skip back 2', 'skip back 3']);
  });

  testWidgets('tapping the other side restarts the count there', (
    tester,
  ) async {
    final rig = Rig();
    addTearDown(rig.logic.dispose);
    rig.tap(TapZone.forward);
    rig.tap(TapZone.forward);
    await wait(tester, 100);
    rig.tap(TapZone.back);
    expect(rig.events, ['skip forward 1', 'skip back 1']);
  });

  testWidgets('the skip chain ends after a pause and taps toggle again', (
    tester,
  ) async {
    final rig = Rig();
    addTearDown(rig.logic.dispose);
    rig.tap(TapZone.forward);
    rig.tap(TapZone.forward);
    await wait(tester, 900);
    expect(rig.events, ['skip forward 1', 'skip-end']);
    rig.tap(TapZone.forward);
    await wait(tester, 350);
    expect(rig.events.last, 'single');
  });

  testWidgets('a double tap in the middle toggles play instead', (
    tester,
  ) async {
    final rig = Rig();
    addTearDown(rig.logic.dispose);
    rig.tap(TapZone.center);
    await wait(tester, 100);
    rig.tap(TapZone.center);
    await wait(tester, 400);
    expect(rig.events, ['center-double']);
  });

  testWidgets('holding speeds up and releasing ends it without a tap', (
    tester,
  ) async {
    final rig = Rig();
    addTearDown(rig.logic.dispose);
    rig.logic.down(TapZone.forward, Offset.zero);
    await wait(tester, 400);
    expect(rig.events, isEmpty);
    await wait(tester, 200);
    expect(rig.events, ['hold-start']);
    rig.logic.up();
    await wait(tester, 400);
    expect(rig.events, ['hold-start', 'hold-end']);
  });

  testWidgets('moving past the slop cancels both the hold and the tap', (
    tester,
  ) async {
    final rig = Rig();
    addTearDown(rig.logic.dispose);
    rig.logic.down(TapZone.back, Offset.zero);
    rig.logic.move(const Offset(60, 0));
    await wait(tester, 700);
    rig.logic.up();
    await wait(tester, 400);
    expect(rig.events, isEmpty);
  });

  testWidgets('a second finger abandons a hold that already began', (
    tester,
  ) async {
    final rig = Rig();
    addTearDown(rig.logic.dispose);
    rig.logic.down(TapZone.center, Offset.zero);
    await wait(tester, 600);
    rig.logic.down(TapZone.back, const Offset(5, 5));
    expect(rig.events, ['hold-start', 'hold-end']);
  });
}
