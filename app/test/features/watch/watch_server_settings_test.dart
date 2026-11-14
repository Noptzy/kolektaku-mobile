import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'watch_harness.dart';

Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> openAudio(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('player-settings')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('settings-row-audio')));
  await tester.pumpAndSettle();
}

void main() {
  group('the audio page of the player settings', () {
    testWidgets('lists the servers inside the settings sheet', (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      await openAudio(tester);
      expect(find.byKey(const Key('player-settings-back')), findsOneWidget);
      expect(find.text('Server 1'), findsOneWidget);
      expect(find.text('Server 2'), findsOneWidget);
      expect(find.byType(ShadSheet), findsOneWidget);
    });

    testWidgets('picking a server closes the sheet and reopens the video', (
      tester,
    ) async {
      final harness = WatchHarness();
      await harness.open(tester);
      await openAudio(tester);
      await tester.tap(find.byKey(const Key('server-option-srv2')));
      await settle(tester);
      expect(harness.resolvedServers.last, 'srv2');
      expect(find.byType(ShadSheet), findsNothing);
    });

    testWidgets('can also try another source from the same page', (
      tester,
    ) async {
      final harness = WatchHarness();
      await harness.open(tester);
      await openAudio(tester);
      await tester.tap(find.byKey(const Key('other-source-option')));
      await settle(tester);
      expect(harness.excluded.last, ['a']);
    });

    testWidgets('the back arrow returns to the settings list', (tester) async {
      final harness = WatchHarness();
      await harness.open(tester);
      await openAudio(tester);
      await tester.tap(find.byKey(const Key('player-settings-back')));
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan pemutar'), findsOneWidget);
      expect(find.byKey(const Key('server-option-srv2')), findsNothing);
    });
  });
}
