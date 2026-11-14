import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Duration parseClock(String text) {
  final parts = text.split(':').map(int.parse).toList();
  return switch (parts.length) {
    3 => Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]),
    _ => Duration(minutes: parts[0], seconds: parts[1]),
  };
}

Duration? shownPosition(WidgetTester tester) {
  final finder = find.textContaining(' / ');
  if (finder.evaluate().isEmpty) return null;
  final text = tester.widget<Text>(finder.first).data!;
  return parseClock(text.split(' / ').first);
}

bool controlsShown(WidgetTester tester) {
  final fade = find.byKey(const Key('controls-fade'));
  if (fade.evaluate().isEmpty) return false;
  return tester.widget<AnimatedOpacity>(fade).opacity > 0.5;
}

Future<bool> waitFor(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  final limit = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(limit)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (condition()) return true;
  }
  return false;
}

Future<void> showControls(WidgetTester tester) async {
  if (controlsShown(tester)) return;
  await tester.tap(find.byKey(const Key('zone-forward')));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> doubleTap(WidgetTester tester, Key zone) async {
  await tester.tap(find.byKey(zone));
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tap(find.byKey(zone));
  await tester.pump(const Duration(milliseconds: 800));
}

Future<void> choose(WidgetTester tester, Key menu, Key option) async {
  await showControls(tester);
  await tester.tap(find.byKey(menu));
  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.byKey(option));
  await tester.pump(const Duration(seconds: 1));
}

bool isLandscape(WidgetTester tester) {
  final size = tester.view.physicalSize;
  return size.width > size.height;
}

Future<void> pumpFor(WidgetTester tester, Duration total) async {
  final limit = DateTime.now().add(total);
  while (DateTime.now().isBefore(limit)) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<Duration> positionAfter(WidgetTester tester, Duration wait) async {
  await pumpFor(tester, wait);
  return shownPosition(tester)!;
}
