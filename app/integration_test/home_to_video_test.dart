import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/app.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/data/core_session.dart';
import 'package:kolektaku/features/watch/player/video_player_engine.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

import 'support/open_watch.dart';
import 'support/watch_driver.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await startCore();
  });

  testWidgets('from the home screen a film plays in three taps', (
    tester,
  ) async {
    var taps = 0;
    Future<void> tap(Finder finder) async {
      taps++;
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 500));
    }

    await tester.pumpWidget(kolektakuScope(child: const KolektakuApp()));
    await tester.pump(const Duration(seconds: 1));
    while (kolektakuRouter.canPop()) {
      kolektakuRouter.pop();
      await tester.pump(const Duration(milliseconds: 500));
    }
    kolektakuRouter.go(Routes.search);
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(EditableText), 'kimi no nawa');
    final listed = await waitFor(
      tester,
      () => find.text('Kimi no Na wa.').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 60),
    );
    expect(listed, isTrue, reason: 'the film was not listed');

    await tap(find.text('Kimi no Na wa.').first);
    final ready = await waitFor(
      tester,
      () => find.text('Tonton film').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 90),
    );
    expect(ready, isTrue, reason: 'the film button never became ready');

    await tap(find.text('Tonton film'));
    final playing = await waitFor(
      tester,
      () => (shownPosition(tester) ?? Duration.zero) > Duration.zero,
      timeout: const Duration(seconds: 120),
    );
    expect(playing, isTrue, reason: 'the video never started');
    expect(taps, lessThanOrEqualTo(3));

    while (kolektakuRouter.canPop()) {
      kolektakuRouter.pop();
      await tester.pump(const Duration(milliseconds: 500));
    }
    await waitUntilReleased(tester: tester);
    expect(VideoPlayerEngine.liveControllers, 0);
  }, timeout: const Timeout(Duration(minutes: 6)));
}
