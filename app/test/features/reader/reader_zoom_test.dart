import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/reader/reader_zoom.dart';

const _screen = 400.0;

void main() {
  group('ReaderZoom', () {
    test('starts unzoomed and centred', () {
      final model = ReaderZoom();
      expect(model.zoom, 1);
      expect(model.pan, 0);
      expect(model.zoomed, isFalse);
      expect(model.widthOf(_screen), _screen);
    });

    test('the zoom stays between normal size and the maximum', () {
      final model = ReaderZoom()..setZoom(9, _screen);
      expect(model.zoom, maxReaderZoom);
      model.setZoom(0.2, _screen);
      expect(model.zoom, 1);
    });

    test('a zoomed page is as wide as the screen times the zoom', () {
      final model = ReaderZoom()..setZoom(2, _screen);
      expect(model.widthOf(_screen), 800);
      expect(model.zoomed, isTrue);
    });

    test('images are decoded at the next step up so they stay sharp', () {
      final model = ReaderZoom();
      final steps = <double, double>{
        1.0: 1.0,
        1.2: 1.5,
        1.5: 1.5,
        1.8: 2.0,
        2.5: maxReaderZoom,
      };
      for (final entry in steps.entries) {
        model.setZoom(entry.key, _screen);
        expect(model.decodeScale, entry.value, reason: '${entry.key}');
      }
    });

    test('panning moves the page but never past its edges', () {
      final model = ReaderZoom()..setZoom(2, _screen);
      model.panBy(-150, _screen);
      expect(model.pan, -150);
      model.panBy(-500, _screen);
      expect(model.pan, -400);
      model.panBy(900, _screen);
      expect(model.pan, 0);
    });

    test('there is nothing to pan while unzoomed', () {
      final model = ReaderZoom()..panBy(-100, _screen);
      expect(model.pan, 0);
    });

    test('zooming out pulls the pan back inside the new edges', () {
      final model = ReaderZoom()
        ..setZoom(3, _screen)
        ..panBy(-800, _screen);
      expect(model.pan, -800);
      model.setZoom(1.5, _screen);
      expect(model.pan, -200);
    });

    test('ending a pinch near normal size snaps back to normal', () {
      final model = ReaderZoom()
        ..startPinch()
        ..setZoom(1.05, _screen)
        ..endPinch(_screen);
      expect(model.zoom, 1);
      expect(model.pinching, isFalse);
    });

    test('ending a pinch at a real zoom keeps it', () {
      final model = ReaderZoom()
        ..startPinch()
        ..setZoom(1.8, _screen)
        ..endPinch(_screen);
      expect(model.zoom, 1.8);
    });

    test('reset puts everything back', () {
      final model = ReaderZoom()
        ..setZoom(2, _screen)
        ..panBy(-100, _screen)
        ..startPinch()
        ..reset();
      expect([model.zoom, model.pan, model.pinching], [1, 0, false]);
    });

    test('listeners hear about each change', () {
      var heard = 0;
      final model = ReaderZoom()..addListener(() => heard++);
      model
        ..setZoom(2, _screen)
        ..panBy(-10, _screen)
        ..startPinch();
      expect(heard, 3);
    });
  });
}
