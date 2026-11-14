import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/home/home_screen.dart';

import 'home_support.dart';

const _sizes = {'390x844': Size(390, 844), '360x780': Size(360, 780)};

void main() {
  _sizes.forEach((label, size) {
    testWidgets('mixed home first screen $label', (tester) async {
      await openHome(tester, size: size);
      await expectLater(
        find.byType(HomeScreen),
        matchesGoldenFile('goldens/home_$label.png'),
      );
    });
  });
}
