import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';
import 'package:kolektaku/widgets/option_chip.dart';

import '../../support/screen_harness.dart';

Future<ScreenHarness> open(WidgetTester tester) async {
  final harness = ScreenHarness();
  await harness.pump(
    tester,
    const SettingsPageScreen(page: SettingsPage.player),
    size: const Size(390, 1200),
  );
  return harness;
}

Future<void> tapChip(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(OptionChip, label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a starting quality is saved', (tester) async {
    final harness = await open(tester);
    await tapChip(tester, '720p');
    expect(harness.settings.saves.single.quality, QualityDto.p720);
  });

  testWidgets('the two switches change auto-next and auto-skip', (
    tester,
  ) async {
    final harness = await open(tester);
    await tester.tap(find.text('Putar episode berikutnya otomatis'));
    await tester.pumpAndSettle();
    expect(harness.settings.saves.last.autoNext, isFalse);
    await tester.tap(find.text('Lewati intro dan outro otomatis'));
    await tester.pumpAndSettle();
    expect(harness.settings.saves.last.autoSkip, isTrue);
  });

  testWidgets('the page explains itself and has a back button', (tester) async {
    await open(tester);
    expect(find.text('Pemutar'), findsOneWidget);
    expect(find.text(SettingsPage.player.intro), findsOneWidget);
    expect(find.byKey(const Key('settings-back')), findsOneWidget);
  });
}
