import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/video_quality.dart';

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('player-settings')));
  await tester.pumpAndSettle();
}

Widget stubPage(VoidCallback close) => const SizedBox.shrink();

Future<void> systemBack(WidgetTester tester) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        'flutter/navigation',
        const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
        (_) {},
      );
  await tester.pumpAndSettle();
}

const adaptive = [
  VideoQuality(id: 'a', height: 1080, label: '1080p'),
  VideoQuality(id: 'b', height: 720, label: '720p'),
];
