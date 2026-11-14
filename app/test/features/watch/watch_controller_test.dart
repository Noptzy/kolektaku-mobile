import 'dart:async';

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
  testWidgets('loading starts a session and lists the episodes', (
    tester,
  ) async {
    final harness = WatchHarness();
    final controller = build(harness);
    await controller.load();
    await settle(tester);
    expect(controller.session, isNotNull);
    expect(controller.loaded!.playback.source, 'a');
    expect(controller.units.length, 12);
    expect(controller.current, 1);
    expect(controller.previous, isNull);
    expect(controller.next!.number, 2);
  });
  testWidgets('the middle of a series has both neighbours', (tester) async {
    final harness = WatchHarness(episode: 5);
    final controller = build(harness, episode: 5);
    await controller.load();
    await settle(tester);
    expect(controller.previous!.number, 4);
    expect(controller.next!.number, 6);
  });
  testWidgets('going to another episode opens it fresh', (tester) async {
    final harness = WatchHarness(startAt: const Duration(seconds: 90));
    final controller = build(harness);
    await controller.load();
    await settle(tester);
    await controller.goTo(controller.next!);
    await settle(tester);
    expect(harness.openedEpisodes, [1, 2]);
    expect(controller.request.episode, 2);
    expect(controller.request.startAt, isNull);
    expect(controller.loaded!.playback.unit.number, 2);
    expect(harness.engine.startedAt.last, Duration.zero);
  });
  testWidgets('a slow earlier load never replaces the newest episode', (
    tester,
  ) async {
    final slow = Completer<void>();
    final harness = WatchHarness();
    final loader = EpisodeLoader(
      open:
          ({
            required MediaRefDto reference,
            required double episode,
            String? preferred,
            required List<String> exclude,
          }) async {
            if (episode == 2) await slow.future;
            return playbackOn('a', episode: episode);
          },
      resolve: ({
        required String source,
        required String episodeId,
        required String server,
      }) async => streamOf('x'),
      units: ({required MediaRefDto reference, String? source}) async =>
          throw StateError('offline'),
    );
    final controller = build(harness, loader: loader);
    await controller.load();
    await settle(tester);
    final stale = controller.goTo(
      (await harness.loader.unitsOrEmpty(reference))[1],
    );
    await controller.goTo((await harness.loader.unitsOrEmpty(reference))[2]);
    slow.complete();
    await stale;
    await settle(tester);
    expect(controller.loaded!.playback.unit.number, 3);
  });
  testWidgets('a missing list of episodes is not fatal', (tester) async {
    final harness = WatchHarness();
    final loader = EpisodeLoader(
      open: ({
        required MediaRefDto reference,
        required double episode,
        String? preferred,
        required List<String> exclude,
      }) async => playbackOn('a'),
      resolve: ({
        required String source,
        required String episodeId,
        required String server,
      }) async => streamOf('x'),
      units: ({required MediaRefDto reference, String? source}) async =>
          throw StateError('offline'),
    );
    final controller = build(harness, loader: loader);
    await controller.load();
    await settle(tester);
    expect(controller.session, isNotNull);
    expect(controller.units, isEmpty);
    expect(controller.next, isNull);
  });
  group('auto continue', () {
    testWidgets('the end of an episode counts down to the next one', (
      tester,
    ) async {
      final harness = WatchHarness();
      final controller = build(harness);
      await controller.load();
      await settle(tester);
      harness.engine.emit(position: harness.engine.length, playing: false);
      expect(controller.autoNext.active, isTrue);
      expect(controller.autoNext.remaining, 5);
      await tester.pump(const Duration(seconds: 5));
      await settle(tester);
      expect(controller.loaded!.playback.unit.number, 2);
      expect(controller.autoNext.active, isFalse);
    });

    testWidgets('the last episode never counts down', (tester) async {
      final harness = WatchHarness(episode: 12);
      final controller = build(harness, episode: 12);
      await controller.load();
      await settle(tester);
      harness.engine.emit(position: harness.engine.length, playing: false);
      expect(controller.autoNext.active, isFalse);
    });

    testWidgets('seeking back from the end cancels the countdown', (
      tester,
    ) async {
      final harness = WatchHarness();
      final controller = build(harness);
      await controller.load();
      await settle(tester);
      harness.engine.emit(position: harness.engine.length, playing: false);
      harness.engine.emit(position: const Duration(minutes: 10), playing: true);
      expect(controller.autoNext.active, isFalse);
      await tester.pump(const Duration(seconds: 10));
      expect(harness.openedEpisodes, [1]);
    });

    testWidgets('cancelling keeps the same episode', (tester) async {
      final harness = WatchHarness();
      final controller = build(harness);
      await controller.load();
      await settle(tester);
      harness.engine.emit(position: harness.engine.length, playing: false);
      controller.autoNext.cancel();
      await tester.pump(const Duration(seconds: 10));
      expect(harness.openedEpisodes, [1]);
    });

    testWidgets('playing now skips the wait', (tester) async {
      final harness = WatchHarness();
      final controller = build(harness);
      await controller.load();
      await settle(tester);
      harness.engine.emit(position: harness.engine.length, playing: false);
      controller.autoNext.now();
      await settle(tester);
      expect(controller.loaded!.playback.unit.number, 2);
    });
  });
}
