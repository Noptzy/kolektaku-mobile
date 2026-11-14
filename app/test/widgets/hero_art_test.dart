import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/hero_art.dart';
import 'package:kolektaku/widgets/poster.dart';

import 'widget_harness.dart';

Future<void> show(WidgetTester tester, String? url) {
  return pumpAtSize(
    tester,
    SizedBox(width: 300, height: 200, child: HeroArt(url: url)),
  );
}

void main() {
  group('HeroArt', () {
    testWidgets('without a cover it shows the placeholder', (tester) async {
      await show(tester, null);
      expect(find.byType(PosterPlaceholder), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('an empty address is treated as no cover', (tester) async {
      await show(tester, '');
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('a cover is sharp, anchored to the top and decoded bounded', (
      tester,
    ) async {
      await show(tester, 'https://x.test/c.jpg');
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://x.test/c.jpg');
      expect(image.fit, BoxFit.cover);
      expect(image.alignment, Alignment.topCenter);
      expect(image.memCacheWidth, lessThanOrEqualTo(2048));
      expect(find.byType(ImageFiltered), findsNothing);
    });
  });
}
