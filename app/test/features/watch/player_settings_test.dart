import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/player/player_settings.dart';
import 'package:kolektaku/features/watch/player/video_quality.dart';

import 'player_extras_ui_support.dart';

const _openers = ['speed', 'subtitles', 'quality'];

Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('player-settings')));
  await tester.pumpAndSettle();
}

const adaptive = [
  VideoQuality(id: 'a', height: 1080, label: '1080p'),
  VideoQuality(id: 'b', height: 720, label: '720p'),
];

void main() {
  group('the button', () {
    testWidgets('is one gear next to the fullscreen button', (tester) async {
      await show(
        tester,
        subtitles: [sub('Indonesian', 'id')],
        qualities: adaptive,
      );
      final gear = tester.getTopLeft(find.byKey(const Key('player-settings')));
      final full = tester.getTopLeft(find.byKey(const Key('fullscreen')));
      expect(gear.dx, lessThan(full.dx));
      expect(gear.dy, full.dy);
      for (final old in _openers) {
        expect(find.byKey(Key(old)), findsNothing, reason: old);
      }
    });

    testWidgets('opens a sheet that lists what can be changed', (tester) async {
      await show(
        tester,
        subtitles: [sub('Indonesian', 'id')],
        qualities: adaptive,
      );
      await openSettings(tester);
      expect(find.text('Pengaturan pemutar'), findsOneWidget);
      expect(find.byKey(const Key('settings-row-quality')), findsOneWidget);
      expect(find.byKey(const Key('settings-row-subtitle')), findsOneWidget);
      expect(find.byKey(const Key('settings-row-speed')), findsOneWidget);
    });

    testWidgets('shows the current value on each row', (tester) async {
      await show(
        tester,
        subtitles: [sub('Indonesian', 'id')],
        qualities: adaptive,
      );
      await openSettings(tester);
      expect(find.text('Resolusi'), findsOneWidget);
      expect(find.text('Otomatis'), findsOneWidget);
      expect(find.text('Kecepatan'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
    });

    testWidgets('a stream with nothing to choose only offers the speed', (
      tester,
    ) async {
      await show(tester);
      await openSettings(tester);
      expect(find.byKey(const Key('settings-row-speed')), findsOneWidget);
      expect(find.byKey(const Key('settings-row-quality')), findsNothing);
      expect(find.byKey(const Key('settings-row-subtitle')), findsNothing);
      expect(find.byKey(const Key('settings-row-audio')), findsNothing);
    });

    testWidgets('closes the sheet before opening the chosen picker', (
      tester,
    ) async {
      await show(tester);
      await openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-row-speed')));
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan pemutar'), findsNothing);
      expect(find.byKey(const Key('option-1.5x')), findsOneWidget);
    });
  });

  group('the audio row', () {
    testWidgets('is there only when the screen can change servers', (
      tester,
    ) async {
      await show(tester, onAudio: () {}, audioLabel: 'Server 1 · Dub');
      await openSettings(tester);
      expect(find.byKey(const Key('settings-row-audio')), findsOneWidget);
      expect(find.text('Server 1 · Dub'), findsOneWidget);
    });

    testWidgets('runs the server change after the sheet closes', (
      tester,
    ) async {
      var opened = 0;
      await show(tester, onAudio: () => opened++, audioLabel: 'Server 1');
      await openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-row-audio')));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(find.text('Pengaturan pemutar'), findsNothing);
    });

    testWidgets('falls back to a plain word without a label', (tester) async {
      await show(tester, onAudio: () {});
      await openSettings(tester);
      expect(find.text('Server'), findsOneWidget);
    });
  });

  group('values', () {
    testWidgets('a subtitle that is off reads Mati', (tester) async {
      final (_, session) = await show(
        tester,
        subtitles: [sub('Indonesian', 'id')],
      );
      session.extras.selectSubtitle(null);
      await tester.pump();
      await openSettings(tester);
      expect(find.text('Mati'), findsOneWidget);
    });

    testWidgets('the resolution row names the chosen track', (tester) async {
      final (_, session) = await show(tester, qualities: adaptive);
      expect(hasResolutions(session), isTrue);
      session.extras.selectTrack('b');
      await tester.pump();
      expect(resolutionValue(session), '720p');
    });

    testWidgets('one resolution means there is nothing to pick', (
      tester,
    ) async {
      final (_, session) = await show(tester);
      expect(hasResolutions(session), isFalse);
      expect(resolutionValue(session), 'Otomatis');
    });
  });
}
