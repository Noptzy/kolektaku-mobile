import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/episode_loader.dart';
import 'package:kolektaku/features/watch/watch_controller.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'watch_fixtures.dart';
import 'watch_harness.dart';

WatchController build(
  WatchHarness harness, {
  double episode = 1,
  EpisodeLoader? loader,
}) {
  final controller = WatchController(
    request: WatchRequest(
      reference: reference,
      kind: MediaKindDto.anime,
      title: 'Kimi no Na wa.',
      episode: episode,
    ),
    loader: loader ?? harness.loader,
    engineFactory: () => harness.engine,
    progress: harness.progress,
    pip: harness.pip,
    autoNextDelay: harness.autoNextDelay,
  );
  addTearDown(controller.dispose);
  return controller;
}

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
}

void main() {
  group('server and source', () {
    testWidgets('another server reopens at the same moment', (tester) async {
      final harness = WatchHarness();
      final controller = build(harness);
      await controller.load();
      await settle(tester);
      harness.engine.emit(position: const Duration(seconds: 75), playing: true);
      await controller.useServer('srv2');
      await settle(tester);
      expect(controller.loaded!.serverId, 'srv2');
      expect(harness.resolvedServers.last, 'srv2');
      expect(harness.engine.startedAt.last, const Duration(seconds: 75));
    });

    testWidgets('choosing the server already in use does nothing', (
      tester,
    ) async {
      final harness = WatchHarness();
      final controller = build(harness);
      await controller.load();
      await settle(tester);
      final before = harness.resolves;
      await controller.useServer(controller.loaded!.serverId);
      expect(harness.resolves, before);
    });

    testWidgets('trying another source skips the current one', (tester) async {
      final harness = WatchHarness();
      final controller = build(harness);
      await controller.load();
      await settle(tester);
      harness.engine.emit(position: const Duration(seconds: 40), playing: true);
      await controller.tryOtherSource();
      await settle(tester);
      expect(harness.excluded.last, ['a']);
      expect(controller.loaded!.playback.source, 'b');
      expect(harness.engine.startedAt.last, const Duration(seconds: 40));
    });
  });
  testWidgets('a failed load reports the error and can be retried', (
    tester,
  ) async {
    final harness = WatchHarness(failToLoad: true);
    final controller = build(harness);
    await controller.load();
    await settle(tester);
    expect(controller.error, isNotNull);
    expect(controller.session, isNull);
    await controller.load();
    await settle(tester);
    expect(controller.error, isNull);
    expect(controller.session, isNotNull);
  });
  testWidgets('disposing closes the session and stops the countdown', (
    tester,
  ) async {
    final harness = WatchHarness();
    final controller = build(harness);
    await controller.load();
    await settle(tester);
    harness.engine.emit(position: harness.engine.length, playing: false);
    controller.dispose();
    await tester.pump(const Duration(seconds: 10));
    expect(harness.engine.disposed, isTrue);
    expect(harness.openedEpisodes, [1]);
  });
}
