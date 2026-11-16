import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/scene_search/scene_search_screen.dart';
import 'package:kolektaku/platform/picture_source.dart';

import '../../support/fake_scene_gateway.dart';
import '../../support/screen_harness.dart';

const _sizes = {'390x844': Size(390, 844), '360x780': Size(360, 780)};

void main() {
  _sizes.forEach((label, size) {
    testWidgets('golden $label start screen', (tester) async {
      final gateway = FakeSceneGateway()..quota = 93;
      await ScreenHarness().pump(
        tester,
        const SceneSearchScreen(),
        size: size,
        extra: [
          sceneGatewayProvider.overrideWithValue(gateway),
          pictureSourceProvider.overrideWithValue(FakePictureSource()),
        ],
      );
      await expectLater(
        find.byType(SceneSearchScreen),
        matchesGoldenFile('goldens/scene_start_$label.png'),
      );
    });
  });
}
