import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'player_extras_ui_support.dart';
import 'player_settings_support.dart';

void main() {
  group('the pages inside the settings sheet', () {
    testWidgets('the chosen list opens inside the same sheet', (tester) async {
      await show(tester);
      await openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-row-speed')));
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan pemutar'), findsNothing);
      expect(find.byKey(const Key('settings-row-speed')), findsNothing);
      expect(find.byKey(const Key('player-settings-back')), findsOneWidget);
      expect(find.text('Kecepatan'), findsOneWidget);
      expect(find.byKey(const Key('option-1.5x')), findsOneWidget);
      expect(find.byType(ShadSheet), findsOneWidget);
    });

    testWidgets('the back arrow returns to the list of settings', (
      tester,
    ) async {
      await show(tester);
      await openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-row-speed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('player-settings-back')));
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan pemutar'), findsOneWidget);
      expect(find.byKey(const Key('settings-row-speed')), findsOneWidget);
      expect(find.byKey(const Key('player-settings-back')), findsNothing);
    });

    testWidgets('the system back goes to the list first, then closes', (
      tester,
    ) async {
      await show(tester);
      await openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-row-speed')));
      await tester.pumpAndSettle();
      await systemBack(tester);
      expect(find.text('Pengaturan pemutar'), findsOneWidget);
      await systemBack(tester);
      expect(find.text('Pengaturan pemutar'), findsNothing);
      expect(find.byType(ShadSheet), findsNothing);
    });

    testWidgets('picking a value applies it and closes the sheet', (
      tester,
    ) async {
      final (_, session) = await show(tester);
      await openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-row-speed')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('option-1.5x')));
      await tester.pumpAndSettle();
      expect(session.engine.snapshot.value.speed, 1.5);
      expect(find.byType(ShadSheet), findsNothing);
    });
  });

  group('the audio row', () {
    testWidgets('is there only when the screen can change servers', (
      tester,
    ) async {
      await show(tester, audioPage: stubPage, audioLabel: 'Server 1 · Dub');
      await openSettings(tester);
      expect(find.byKey(const Key('settings-row-audio')), findsOneWidget);
      expect(find.text('Server 1 · Dub'), findsOneWidget);
    });

    testWidgets('shows its page in the sheet and can close it', (tester) async {
      await show(
        tester,
        audioPage: (close) => ShadButton(
          key: const Key('audio-pick'),
          onPressed: close,
          child: const Text('pilih'),
        ),
        audioLabel: 'Server 1',
      );
      await openSettings(tester);
      await tester.tap(find.byKey(const Key('settings-row-audio')));
      await tester.pumpAndSettle();
      expect(find.text('Suara (sub atau dub)'), findsOneWidget);
      expect(find.byKey(const Key('player-settings-back')), findsOneWidget);
      await tester.tap(find.byKey(const Key('audio-pick')));
      await tester.pumpAndSettle();
      expect(find.byType(ShadSheet), findsNothing);
    });

    testWidgets('falls back to a plain word without a label', (tester) async {
      await show(tester, audioPage: stubPage);
      await openSettings(tester);
      expect(find.text('Server'), findsOneWidget);
    });
  });
}
