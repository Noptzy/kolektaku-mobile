import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/data/core_session.dart';
import 'package:kolektaku/features/watch/watch_request.dart';
import 'package:kolektaku/features/watch/watch_screen.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'support/pipeline_steps.dart';
import 'support/recording_pip.dart';
import 'support/watch_driver.dart';

const kimiNoNaWa = 21519;

void mark(String name) => debugPrint('MARK $name');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await startCore();
    await openDetail(MediaKindDto.anime, catalogRef(kimiNoNaWa));
  });

  testWidgets(
    'home enters a small window whose button pauses and resumes the video',
    (tester) async {
      final pip = RecordingPip();
      await tester.pumpWidget(
        ShadApp(
          darkTheme: kolektakuDarkTheme(),
          themeMode: ThemeMode.dark,
          home: WatchScreen(
            pip: pip,
            request: WatchRequest(
              reference: catalogRef(kimiNoNaWa),
              kind: MediaKindDto.anime,
              title: 'Kimi no Na wa.',
              episode: 1,
            ),
          ),
        ),
      );
      final started = await waitFor(
        tester,
        () => (shownPosition(tester) ?? Duration.zero) > Duration.zero,
        timeout: const Duration(seconds: 90),
      );
      expect(started, isTrue);
      mark('READY_FOR_HOME');

      final entered = await waitFor(tester, () => pip.modes.contains(true));
      expect(entered, isTrue, reason: 'Home did not open the small window');
      expect(find.byKey(const Key('play-pause')), findsNothing);
      mark('IN_PIP');

      final paused = await waitFor(
        tester,
        () => pip.playingUpdates.contains(false),
        timeout: const Duration(seconds: 120),
      );
      expect(paused, isTrue, reason: 'the small window button did not pause');
      mark('PAUSED');

      final resumed = await waitFor(
        tester,
        () => pip.playingUpdates.last == true,
        timeout: const Duration(seconds: 120),
      );
      expect(resumed, isTrue, reason: 'the button did not resume');
      mark('RESUMED');

      final back = await waitFor(
        tester,
        () => pip.modes.isNotEmpty && pip.modes.last == false,
        timeout: const Duration(seconds: 120),
      );
      expect(back, isTrue, reason: 'the full screen did not come back');
      expect(find.byKey(const Key('episode-label')), findsOneWidget);
      mark('BACK_FULL');
      expect(pip.toggles, greaterThanOrEqualTo(2));
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
