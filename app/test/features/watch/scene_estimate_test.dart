import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/player_session.dart';
import 'package:kolektaku/features/watch/scene_estimate_bar.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/platform/stream_resolver.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';

import '../../widgets/widget_harness.dart';
import 'fake_engine.dart';
import 'watch_fixtures.dart';

PlayerSession sessionOn(FakeEngine engine) {
  return PlayerSession(
    engine: engine,
    stream: ResolvedStream(
      set: StreamSetDto(
        sources: [
          StreamSourceDto(
            url: 'https://x.test/v.mp4',
            kind: 'mp4',
            quality: 720,
            label: '720p',
            isDefault: true,
          ),
        ],
        headers: const [],
        subtitles: const [],
        skips: const [],
      ),
      headers: const {},
    ),
    refetch: () async => streamOf('x'),
  );
}

Future<(FakeEngine, PlayerSession)> show(
  WidgetTester tester, {
  Duration? sourceLength = const Duration(seconds: 1418),
  VoidCallback? onOthers,
}) async {
  final engine = FakeEngine();
  final session = sessionOn(engine);
  await session.start(const Duration(seconds: 100));
  addTearDown(session.close);
  await pumpAtSize(
    tester,
    SceneEstimateBar(
      session: session,
      estimate: SceneEstimate(
        at: const Duration(seconds: 100),
        sourceLength: sourceLength,
      ),
      onOthers: onOthers ?? () {},
    ),
  );
  return (engine, session);
}

void main() {
  testWidgets('says the position is an estimate and why', (tester) async {
    await show(tester);
    expect(find.text('Perkiraan posisi'), findsOneWidget);
    expect(find.textContaining('bisa meleset beberapa detik'), findsOneWidget);
  });

  testWidgets('minus ten and plus ten move the video', (tester) async {
    final (engine, session) = await show(tester);
    engine.emit(position: const Duration(seconds: 100), playing: true);
    await tester.tap(find.byKey(const Key('estimate-back')));
    await tester.pump();
    expect(engine.log.last, 'seek 90');
    await tester.tap(find.byKey(const Key('estimate-forward')));
    await tester.pump();
    expect(
      session.engine.snapshot.value.position,
      const Duration(seconds: 100),
    );
  });

  testWidgets('seeking stays inside the video', (tester) async {
    final (engine, _) = await show(tester);
    engine.emit(position: const Duration(seconds: 4), playing: true);
    await tester.tap(find.byKey(const Key('estimate-back')));
    await tester.pump();
    expect(engine.log.last, 'seek 0');
  });

  testWidgets('a video of a very different length shows the warning', (
    tester,
  ) async {
    final (engine, _) = await show(tester);
    engine.length = const Duration(seconds: 1600);
    engine.emit(position: const Duration(seconds: 100));
    await tester.pump();
    expect(find.byKey(const Key('length-warning')), findsOneWidget);
  });

  testWidgets('a video of about the same length shows none', (tester) async {
    final (engine, _) = await show(tester);
    engine.length = const Duration(seconds: 1430);
    engine.emit(position: const Duration(seconds: 100));
    await tester.pump();
    expect(find.byKey(const Key('length-warning')), findsNothing);
  });

  testWidgets('without a known source length there is never a warning', (
    tester,
  ) async {
    final (engine, _) = await show(tester, sourceLength: null);
    engine.length = const Duration(seconds: 3000);
    engine.emit(position: const Duration(seconds: 100));
    await tester.pump();
    expect(find.byKey(const Key('length-warning')), findsNothing);
  });

  testWidgets('the other results link goes back', (tester) async {
    var taps = 0;
    await show(tester, onOthers: () => taps++);
    await tester.tap(find.byKey(const Key('estimate-others')));
    expect(taps, 1);
  });
}
