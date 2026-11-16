import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/scene_search/scene_search_screen.dart';
import 'package:kolektaku/features/scene_search/scene_steps.dart';
import 'package:kolektaku/platform/picture_source.dart';

import '../../support/fake_scene_gateway.dart';
import '../../support/screen_harness.dart';

Future<FakeSceneGateway> open(
  WidgetTester tester, {
  int? quota = 93,
  Size size = const Size(360, 780),
}) async {
  final gateway = FakeSceneGateway()..quota = quota;
  await ScreenHarness().pump(
    tester,
    const SceneSearchScreen(),
    size: size,
    extra: [
      sceneGatewayProvider.overrideWithValue(gateway),
      pictureSourceProvider.overrideWithValue(FakePictureSource()),
    ],
  );
  return gateway;
}

void main() {
  testWidgets('the start screen shows the three steps in order', (
    tester,
  ) async {
    await open(tester);
    expect(sceneSteps, hasLength(3));
    for (final step in sceneSteps) {
      await tester.ensureVisible(find.text(step));
      expect(find.text(step), findsOneWidget);
    }
  });

  testWidgets('one good example and two failing ones are shown', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(find.byKey(const Key('example-fanart')));
    expect(find.text('Gambar seperti ini berhasil'), findsOneWidget);
    expect(find.text('Sering gagal'), findsNWidgets(2));
    expect(find.byKey(const Key('example-tilted')), findsOneWidget);
    expect(find.byKey(const Key('example-fanart')), findsOneWidget);
  });

  testWidgets('the remaining quota shows before any search', (tester) async {
    final gateway = await open(tester, quota: 93);
    expect(gateway.quotaReads, 1);
    expect(find.text('Sisa pencarian gambar hari ini: 93'), findsOneWidget);
    expect(gateway.imageSizes, isEmpty);
  });

  testWidgets('an unknown quota leaves no note', (tester) async {
    await open(tester, quota: null);
    expect(find.textContaining('Sisa pencarian'), findsNothing);
  });

  for (final size in const [Size(360, 780), Size(390, 844)]) {
    testWidgets('both picture buttons stay on screen at $size', (tester) async {
      await open(tester, size: size);
      for (final key in const [Key('take-photo'), Key('pick-file')]) {
        final box = tester.getRect(find.byKey(key));
        expect(box.left, greaterThanOrEqualTo(0), reason: '$key');
        expect(box.right, lessThanOrEqualTo(size.width), reason: '$key');
        expect(box.bottom, lessThanOrEqualTo(size.height), reason: '$key');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
