import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/data/core_session.dart';
import 'package:kolektaku/features/watch/player/video_player_engine.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

import 'support/open_watch.dart';
import 'support/pipeline_steps.dart';
import 'support/watch_driver.dart';

const kimiNoNaWa = 21519;
const title = 'Kimi no Na wa.';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await startCore();
    await openDetail(MediaKindDto.anime, catalogRef(kimiNoNaWa));
  });

  tearDown(() async {
    while (kolektakuRouter.canPop()) {
      kolektakuRouter.pop();
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    await waitUntilReleased();
  });

  testWidgets('the video keeps playing for at least thirty seconds', (
    tester,
  ) async {
    await openWatch(tester, catalogId: kimiNoNaWa, title: title);
    final reached = await waitFor(
      tester,
      () =>
          (shownPosition(tester) ?? Duration.zero) >=
          const Duration(seconds: 30),
      timeout: const Duration(seconds: 60),
    );
    expect(reached, isTrue, reason: 'playback never reached thirty seconds');
    expect(find.byKey(const Key('retry')), findsNothing);
    expect(VideoPlayerEngine.liveControllers, 1);
    await leaveWatch(tester);
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('pausing freezes the picture and resuming moves it again', (
    tester,
  ) async {
    await openWatch(tester, catalogId: kimiNoNaWa, title: title);
    await showControls(tester);
    await tester.tap(find.byKey(const Key('play-pause')));
    await tester.pump(const Duration(seconds: 1));
    final frozen = shownPosition(tester)!;
    final later = await positionAfter(tester, const Duration(seconds: 3));
    expect(later - frozen, lessThan(const Duration(milliseconds: 600)));
    await showControls(tester);
    await tester.tap(find.byKey(const Key('play-pause')));
    final moving = await positionAfter(tester, const Duration(seconds: 4));
    expect(moving - later, greaterThan(const Duration(seconds: 1)));
    await leaveWatch(tester);
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('dragging the seek bar jumps far into the film', (tester) async {
    await openWatch(tester, catalogId: kimiNoNaWa, title: title);
    await showControls(tester);
    final slider = find.byKey(const Key('seek-bar'));
    final width = tester.getSize(slider).width;
    await tester.drag(slider, Offset(width * 0.5, 0));
    await tester.pump(const Duration(seconds: 4));
    expect(shownPosition(tester)!, greaterThan(const Duration(minutes: 20)));
    await leaveWatch(tester);
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('a start time opens the film at exactly that moment', (
    tester,
  ) async {
    await openWatch(
      tester,
      catalogId: kimiNoNaWa,
      title: title,
      startAt: const Duration(minutes: 10),
    );
    debugPrint('MARK FIRST_POSITION ${shownPosition(tester)}');
    final clock = Stopwatch()..start();
    final reached = await waitFor(
      tester,
      () =>
          (shownPosition(tester) ?? Duration.zero) >=
          const Duration(minutes: 10),
      timeout: const Duration(seconds: 30),
    );
    debugPrint('MARK START_SEEK_MS ${clock.elapsedMilliseconds}');
    expect(reached, isTrue, reason: 'the film never reached the start time');
    expect(
      shownPosition(tester)!,
      lessThan(const Duration(minutes: 10, seconds: 30)),
    );
    await leaveWatch(tester);
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('a stream with an HLS source plays that source when offered', (
    tester,
  ) async {
    final stream = await resolveFirstServer(catalogRef(kimiNoNaWa), 1);
    final kinds = stream.set.sources.map((source) => source.kind).toSet();
    debugPrint('MARK STREAM_KINDS $kinds');
    final hls = stream.set.sources.where((source) => source.kind == 'hls');
    if (hls.isEmpty) return;
    final position = await playedFor(
      stream.withFirst(hls.first),
      const Duration(seconds: 8),
    );
    expect(position, greaterThan(const Duration(seconds: 3)));
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('opening and leaving the player three times leaks nothing', (
    tester,
  ) async {
    for (var round = 0; round < 3; round++) {
      await openWatch(tester, catalogId: kimiNoNaWa, title: title);
      expect(VideoPlayerEngine.liveControllers, 1);
      await leaveWatch(tester);
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}
