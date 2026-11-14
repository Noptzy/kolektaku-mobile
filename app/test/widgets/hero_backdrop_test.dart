import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/hero_backdrop.dart';

import 'widget_harness.dart';

Future<void> show(WidgetTester tester, String? url) {
  return pumpAtSize(
    tester,
    SizedBox(width: 300, height: 200, child: HeroBackdrop(url: url)),
  );
}

void main() {
  group('HeroBackdrop', () {
    testWidgets('without a cover it is only the dark base and fade', (
      tester,
    ) async {
      await show(tester, null);
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('an empty address is treated as no cover', (tester) async {
      await show(tester, '');
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('a cover is blurred and decoded small to stay cheap', (
      tester,
    ) async {
      await show(tester, 'https://x.test/c.jpg');
      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(image.imageUrl, 'https://x.test/c.jpg');
      expect(image.memCacheWidth, lessThanOrEqualTo(200));
      expect(find.byType(ImageFiltered), findsOneWidget);
    });
  });
}
