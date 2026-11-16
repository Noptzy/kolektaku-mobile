import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/reader_zoom.dart';
import 'package:kolektaku/features/reader/scroll_anchor.dart';
import 'package:kolektaku/features/reader/stack_metrics.dart';

const _screen = 400.0;

void main() {
  group('the model keeps the point under the fingers in place', () {
    test('zooming around the middle keeps the middle of the page there', () {
      final model = ReaderZoom()
        ..setZoom(2, _screen, focal: const Offset(200, 300));
      expect(model.pan, -200);
      expect(model.focalY, 300);
      final under = 200 - model.pan;
      expect(under / model.zoom, 200);
    });

    test('zooming around the left edge does not slide the page', () {
      final model = ReaderZoom()
        ..setZoom(2, _screen, focal: const Offset(0, 0));
      expect(model.pan, 0);
    });

    test('zooming around the right edge keeps the right edge there', () {
      final model = ReaderZoom()
        ..setZoom(3, _screen, focal: const Offset(400, 0));
      expect(model.pan, -800);
    });

    test('zooming further around a moved point keeps that point fixed', () {
      final model = ReaderZoom()
        ..setZoom(2, _screen, focal: const Offset(300, 100))
        ..setZoom(3, _screen, focal: const Offset(300, 100));
      final under = (300 - model.pan) / model.zoom;
      expect(under, closeTo(300, 1e-9));
    });

    test('zooming out around a point pulls the page back and stays inside', () {
      final model = ReaderZoom()
        ..setZoom(3, _screen, focal: const Offset(100, 0))
        ..setZoom(1, _screen, focal: const Offset(100, 0));
      expect(model.pan, 0);
    });

    test('without a focal point the page keeps the old behaviour', () {
      final model = ReaderZoom()
        ..setZoom(2, _screen)
        ..panBy(-150, _screen);
      expect(model.pan, -150);
      expect(model.focalY, 0);
    });
  });

  group('the scroll follows the same point', () {
    late ScrollController scroll;
    late ScrollAnchor anchor;

    Future<void> mount(WidgetTester tester) async {
      scroll = ScrollController(initialScrollOffset: 400);
      addTearDown(scroll.dispose);
      anchor = ScrollAnchor(metrics: StackMetrics());
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            height: 600,
            child: ListView(
              controller: scroll,
              children: const [SizedBox(height: 4000)],
            ),
          ),
        ),
      );
    }

    testWidgets('zooming in around a point keeps its place on screen', (
      tester,
    ) async {
      await mount(tester);
      anchor.followZoom(scroll, 2, focalY: 300);
      expect(scroll.offset, (400 + 300) * 2 - 300);
    });

    testWidgets('without a focal point it scales from the top as before', (
      tester,
    ) async {
      await mount(tester);
      anchor.followZoom(scroll, 2);
      expect(scroll.offset, 800);
    });

    testWidgets('zooming back out undoes the move around the same point', (
      tester,
    ) async {
      await mount(tester);
      anchor.followZoom(scroll, 2, focalY: 250);
      anchor.followZoom(scroll, 1, focalY: 250);
      expect(scroll.offset, closeTo(400, 1e-9));
    });

    testWidgets('an unchanged zoom does not move anything', (tester) async {
      await mount(tester);
      anchor.followZoom(scroll, 1, focalY: 300);
      expect(scroll.offset, 400);
    });
  });

  group('pinching on the surface', () {
    testWidgets('two fingers zoom around the point between them', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(_screen, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final model = ReaderZoom();
      addTearDown(model.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(size: Size(_screen, 800)),
            child: ZoomSurface(
              model: model,
              builder: (context, width) => ColoredBox(
                key: const Key('page'),
                color: const Color(0xFF123456),
                child: SizedBox(width: width, height: 800),
              ),
            ),
          ),
        ),
      );
      final left = await tester.startGesture(
        const Offset(300, 600),
        pointer: 1,
      );
      final right = await tester.startGesture(
        const Offset(340, 600),
        pointer: 2,
      );
      await left.moveBy(const Offset(-20, 0));
      await right.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(model.zoom, greaterThan(1.5));
      expect(model.focalY, closeTo(600, 1e-6));
      final under = (320 - model.pan) / model.zoom;
      expect(under, closeTo(320, 5));
      await left.up();
      await right.up();
    });
  });
}
