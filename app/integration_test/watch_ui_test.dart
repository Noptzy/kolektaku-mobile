import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/app.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/data/core_session.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/src/rust/api/library.dart' as shelf;
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

import 'support/pipeline_steps.dart';
import 'support/watch_driver.dart';

const kimiNoNaWa = 21519;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await startCore();
    await openDetail(MediaKindDto.anime, catalogRef(kimiNoNaWa));
  });

  testWidgets(
    'the real player plays, skips, changes speed and quality, goes fullscreen and saves progress',
    (tester) async {
      await tester.pumpWidget(kolektakuScope(child: const KolektakuApp()));
      await tester.pump(const Duration(seconds: 1));
      kolektakuRouter.push(
        '/watch',
        extra: WatchRequest(
          reference: catalogRef(kimiNoNaWa),
          kind: MediaKindDto.anime,
          title: 'Kimi no Na wa.',
          episode: 1,
        ),
      );
      final started = await waitFor(
        tester,
        () => (shownPosition(tester) ?? Duration.zero) > Duration.zero,
        timeout: const Duration(seconds: 90),
      );
      expect(started, isTrue, reason: 'the video never started');

      await tester.pump(const Duration(seconds: 4));
      final beforeSkip = shownPosition(tester)!;
      expect(beforeSkip, greaterThan(const Duration(seconds: 2)));

      await doubleTap(tester, const Key('zone-forward'));
      final afterSkip = shownPosition(tester)!;
      expect(
        afterSkip - beforeSkip,
        greaterThanOrEqualTo(const Duration(seconds: 9)),
      );

      await choose(tester, const Key('speed'), const Key('option-1.5x'));
      expect(find.text('1.5x'), findsOneWidget);

      await showControls(tester);
      await tester.tap(find.byKey(const Key('quality')));
      await tester.pump(const Duration(seconds: 1));
      final options = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('option-') &&
            (widget.key! as ValueKey<String>).value.endsWith('p'),
      );
      expect(options, findsWidgets);
      await tester.tap(options.last);
      await tester.pump(const Duration(seconds: 6));
      final afterQuality = shownPosition(tester)!;
      expect(afterQuality, greaterThan(afterSkip));

      await showControls(tester);
      await tester.tap(find.byKey(const Key('fullscreen')));
      await tester.pump(const Duration(seconds: 2));
      expect(isLandscape(tester), isTrue);
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 2));
      expect(isLandscape(tester), isFalse);
      expect(find.byKey(const Key('episode-label')), findsOneWidget);

      kolektakuRouter.pop();
      await tester.pump(const Duration(seconds: 2));
      final saved = await shelf.libraryLastProgress(
        kind: MediaKindDto.anime,
        reference: catalogRef(kimiNoNaWa),
      );
      expect(saved, isNotNull);
      expect(saved!.position, greaterThan(5));
    },
    timeout: const Timeout(Duration(minutes: 6)),
  );
}
