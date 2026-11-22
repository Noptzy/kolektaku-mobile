import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/swipe_toast.dart';

import 'widget_harness.dart';

const _message = 'Dihapus dari riwayat.';

Future<List<int>> _pump(WidgetTester tester) async {
  final events = <int>[0, 0];
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpAtSize(
    tester,
    Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        child: SwipeToast(
          message: _message,
          actionLabel: 'Urungkan',
          onAction: () => events[0]++,
          onClosed: () => events[1]++,
          duration: const Duration(seconds: 4),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
  return events;
}

Future<void> _settle(WidgetTester tester, [int ms = 400]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

Finder get _text => find.text(_message);

void main() {
  testWidgets('appears with its message and action', (tester) async {
    await _pump(tester);
    expect(_text, findsOneWidget);
    expect(find.text('Urungkan'), findsOneWidget);
  });

  testWidgets('closes by itself after its time', (tester) async {
    final events = await _pump(tester);
    await tester.pump(const Duration(seconds: 4));
    await _settle(tester);
    expect(events[1], 1);
  });

  testWidgets('the action reports and does not close by itself', (
    tester,
  ) async {
    final events = await _pump(tester);
    await tester.tap(find.byKey(const Key('toast-action')));
    expect(events[0], 1);
    expect(events[1], 0);
  });

  testWidgets('the action is at least 48 dp tall', (tester) async {
    await _pump(tester);
    final size = tester.getSize(find.byKey(const Key('toast-action')));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('a short swipe snaps back and the timer waits for the finger', (
    tester,
  ) async {
    final events = await _pump(tester);
    final origin = tester.getTopLeft(find.byKey(const Key('toast-action')));
    final gesture = await tester.startGesture(tester.getCenter(_text));
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));
    expect(events[1], 0, reason: 'finger down keeps it open');
    await gesture.up();
    await _settle(tester);
    expect(tester.getTopLeft(find.byKey(const Key('toast-action'))), origin);
    expect(events[1], 0);
    await tester.pump(const Duration(seconds: 4));
    await _settle(tester);
    expect(events[1], 1, reason: 'the timer starts again after release');
  });

  testWidgets('a long swipe down closes', (tester) async {
    final events = await _pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(_text));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    await gesture.up();
    await _settle(tester);
    expect(events[1], 1);
  });

  testWidgets('a long swipe sideways closes in either direction', (
    tester,
  ) async {
    for (final dx in [-120.0, 120.0]) {
      final events = await _pump(tester);
      final gesture = await tester.startGesture(tester.getCenter(_text));
      await gesture.moveBy(Offset(dx / 2, 0));
      await tester.pump();
      await gesture.moveBy(Offset(dx / 2, 0));
      await tester.pump();
      await gesture.up();
      await _settle(tester);
      expect(events[1], 1, reason: 'dx=$dx');
    }
  });

  testWidgets('a quick short flick closes', (tester) async {
    final events = await _pump(tester);
    final gesture = await tester.startGesture(tester.getCenter(_text));
    await gesture.moveBy(
      const Offset(0, 20),
      timeStamp: const Duration(milliseconds: 10),
    );
    await gesture.moveBy(
      const Offset(0, 20),
      timeStamp: const Duration(milliseconds: 20),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 20));
    await _settle(tester);
    expect(events[1], 1);
  });

  testWidgets('with animations off it still closes', (tester) async {
    final events = <int>[0];
    await pumpAtSize(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SwipeToast(
            message: _message,
            actionLabel: 'Urungkan',
            onAction: () {},
            onClosed: () => events[0]++,
            duration: const Duration(seconds: 2),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(events[0], 1);
  });
}
