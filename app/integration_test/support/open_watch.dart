import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/app.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/features/watch/player/video_player_engine.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'pipeline_steps.dart';
import 'watch_driver.dart';

Future<void> openWatch(
  WidgetTester tester, {
  required int catalogId,
  required String title,
  Duration? startAt,
}) async {
  await tester.pumpWidget(kolektakuScope(child: const KolektakuApp()));
  await tester.pump(const Duration(seconds: 1));
  while (kolektakuRouter.canPop()) {
    kolektakuRouter.pop();
    await tester.pump(const Duration(milliseconds: 500));
  }
  await waitUntilReleased();
  kolektakuRouter.push(
    '/watch',
    extra: WatchRequest(
      reference: catalogRef(catalogId),
      kind: MediaKindDto.anime,
      title: title,
      episode: 1,
      startAt: startAt,
    ),
  );
  final started = await waitFor(
    tester,
    () => (shownPosition(tester) ?? Duration.zero) > Duration.zero,
    timeout: const Duration(seconds: 90),
  );
  expect(started, isTrue, reason: 'the video never started');
}

Future<void> leaveWatch(WidgetTester tester) async {
  kolektakuRouter.pop();
  await tester.pump(const Duration(seconds: 1));
  await waitUntilReleased(tester: tester);
}

Future<void> waitUntilReleased({WidgetTester? tester}) async {
  final limit = DateTime.now().add(const Duration(seconds: 20));
  while (VideoPlayerEngine.liveControllers > 0 &&
      DateTime.now().isBefore(limit)) {
    if (tester != null) {
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
  expect(VideoPlayerEngine.liveControllers, 0, reason: 'a player leaked');
}
