import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/reader_zoom.dart';

const _screen = 400.0;

void main() {
  group('ZoomSurface', () {
    late ReaderZoom model;
    late List<double> widths;

    Future<void> show(WidgetTester tester) async {
      tester.view.physicalSize = const Size(_screen, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      model = ReaderZoom();
      addTearDown(model.dispose);
      widths = [];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(_screen, 800)),
            child: ZoomSurface(
              model: model,
              builder: (context, width) {
                widths.add(width);
                return Container(
                  key: const Key('page'),
                  width: width,
                  height: 500,
                  color: const Color(0xFF123456),
                );
              },
            ),
          ),
        ),
      );
    }

    Future<(TestGesture, TestGesture)> twoFingers(
      WidgetTester tester, {
      double gap = 100,
    }) async {
      final center = tester.getCenter(find.byKey(const Key('page')));
      final left = await tester.startGesture(
        center - Offset(gap / 2, 0),
        pointer: 101,
      );
      final right = await tester.startGesture(
        center + Offset(gap / 2, 0),
        pointer: 102,
      );
      return (left, right);
    }

    testWidgets('lays its child out as wide as the model says', (tester) async {
      await show(tester);
      expect(widths.last, _screen);
      model.setZoom(2, _screen);
      await tester.pump();
      expect(widths.last, _screen * 2);
    });

    testWidgets('two fingers moving apart zoom in', (tester) async {
      await show(tester);
      final (left, right) = await twoFingers(tester);
      expect(model.pinching, isTrue);
      await left.moveBy(const Offset(-50, 0));
      await right.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(model.zoom, closeTo(2, 0.01));
      await left.up();
      await right.up();
      expect(model.pinching, isFalse);
      expect(model.zoom, closeTo(2, 0.01));
    });

    testWidgets('moving back together near the start snaps to normal', (
      tester,
    ) async {
      await show(tester);
      final (left, right) = await twoFingers(tester);
      await left.moveBy(const Offset(-50, 0));
      await right.moveBy(const Offset(50, 0));
      await left.moveBy(const Offset(48, 0));
      await right.moveBy(const Offset(-48, 0));
      await left.up();
      await right.up();
      expect(model.zoom, 1);
    });

    testWidgets('a single finger never changes the zoom', (tester) async {
      await show(tester);
      final finger = await tester.startGesture(const Offset(200, 300));
      await finger.moveBy(const Offset(120, 0));
      await finger.up();
      expect(model.zoom, 1);
      expect(model.pan, 0);
    });

    testWidgets('a single finger pans sideways once zoomed', (tester) async {
      await show(tester);
      model.setZoom(2, _screen);
      await tester.pump();
      final finger = await tester.startGesture(const Offset(300, 300));
      await finger.moveBy(const Offset(-120, 0));
      await tester.pump();
      expect(model.pan, -120);
      expect(tester.getTopLeft(find.byKey(const Key('page'))).dx, -120);
      await finger.up();
    });

    testWidgets('the page cannot be dragged past its left edge', (
      tester,
    ) async {
      await show(tester);
      model.setZoom(2, _screen);
      await tester.pump();
      final finger = await tester.startGesture(const Offset(100, 300));
      await finger.moveBy(const Offset(300, 0));
      await tester.pump();
      expect(model.pan, 0);
      await finger.up();
    });

    testWidgets('lifting one finger of a pinch ends it', (tester) async {
      await show(tester);
      final (left, right) = await twoFingers(tester);
      await left.up();
      expect(model.pinching, isFalse);
      await right.up();
    });
  });
}
