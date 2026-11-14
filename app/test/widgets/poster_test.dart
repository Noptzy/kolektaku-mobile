import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/poster.dart';

import 'widget_harness.dart';

void main() {
  group('decodeWidth', () {
    test('multiplies by the pixel ratio and rounds', () {
      expect(decodeWidth(112, 2.75), 308);
      expect(decodeWidth(100, 1), 100);
    });

    test('very wide boxes are capped to keep memory sane', () {
      expect(decodeWidth(3000, 3), 2048);
    });

    test('unknown or unbounded widths mean no hint', () {
      expect(decodeWidth(double.infinity, 2), isNull);
      expect(decodeWidth(0, 2), isNull);
      expect(decodeWidth(double.nan, 2), isNull);
    });

    test('at least one pixel is requested', () {
      expect(decodeWidth(0.1, 1), 1);
    });
  });

  group('Poster', () {
    testWidgets('without an address shows the placeholder', (tester) async {
      await pumpAtSize(
        tester,
        const SizedBox(width: 100, child: Poster(url: null)),
      );
      expect(find.byType(PosterPlaceholder), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('an empty address shows the placeholder too', (tester) async {
      await pumpAtSize(
        tester,
        const SizedBox(width: 100, child: Poster(url: '')),
      );
      expect(find.byType(PosterPlaceholder), findsOneWidget);
    });

    testWidgets('a real address asks for a decode no wider than the box', (
      tester,
    ) async {
      await pumpAtSize(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 100,
            child: Poster(url: 'https://x.test/p.jpg'),
          ),
        ),
      );
      final image = tester.widget<Image>(find.byType(Image));
      final provider = image.image as ResizeImage;
      expect(provider.width, 100);
      expect(image.gaplessPlayback, isTrue);
    });
  });
}
