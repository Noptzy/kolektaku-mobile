import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/page_image.dart';

import '../../support/decode.dart';
import 'reader_harness.dart';

const _width = 390.0;

double listWidth(WidgetTester tester) =>
    tester.getSize(find.byType(ListView)).width;

double scrolled(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable).first)
    .position
    .pixels;

Future<(TestGesture, TestGesture)> fingers(WidgetTester tester) async {
  const center = Offset(_width / 2, 400);
  final left = await tester.startGesture(
    center - const Offset(50, 0),
    pointer: 101,
  );
  final right = await tester.startGesture(
    center + const Offset(50, 0),
    pointer: 102,
  );
  return (left, right);
}

Future<void> pinchOut(WidgetTester tester) async {
  final (left, right) = await fingers(tester);
  await left.moveBy(const Offset(-50, 0));
  await right.moveBy(const Offset(50, 0));
  await left.up();
  await right.up();
  await tester.pump(const Duration(milliseconds: 100));
  await decoded(tester);
}

double barOpacity(WidgetTester tester, String key) {
  final fade = find.ancestor(
    of: find.byKey(Key(key)),
    matching: find.byType(AnimatedOpacity),
  );
  return tester.widget<AnimatedOpacity>(fade.first).opacity;
}

void main() {
  testWidgets('pinching out makes the pages wider than the screen', (
    tester,
  ) async {
    await ReaderHarness().open(tester);
    expect(listWidth(tester), _width);
    await pinchOut(tester);
    expect(listWidth(tester), closeTo(_width * 2, 2));
    expect(find.byType(PageImage), findsWidgets);
  });

  testWidgets('pinching back in returns to the normal width', (tester) async {
    await ReaderHarness().open(tester);
    await pinchOut(tester);
    final (left, right) = await fingers(tester);
    await left.moveBy(const Offset(50, 0));
    await right.moveBy(const Offset(-50, 0));
    await left.up();
    await right.up();
    await tester.pump(const Duration(milliseconds: 100));
    expect(listWidth(tester), _width);
  });

  testWidgets('zooming keeps the point between the fingers where it was', (
    tester,
  ) async {
    await ReaderHarness().open(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump(const Duration(milliseconds: 300));
    await decoded(tester);
    final before = scrolled(tester);
    expect(before, greaterThan(300));
    await pinchOut(tester);
    expect(scrolled(tester), closeTo((before + 400) * 2 - 400, before * 0.15));
  });

  testWidgets('a tap on a zoomed page still shows or hides the bars', (
    tester,
  ) async {
    await ReaderHarness().open(tester);
    await pinchOut(tester);
    expect(barOpacity(tester, 'page-counter'), 1);
    await tester.tapAt(const Offset(195, 400));
    await tester.pump(const Duration(milliseconds: 300));
    expect(barOpacity(tester, 'page-counter'), 0);
  });

  testWidgets('reading by scrolling still works while zoomed', (tester) async {
    await ReaderHarness().open(tester);
    await pinchOut(tester);
    final before = scrolled(tester);
    await tester.dragFrom(const Offset(195, 600), const Offset(0, -300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(scrolled(tester), greaterThan(before + 100));
  });
}
