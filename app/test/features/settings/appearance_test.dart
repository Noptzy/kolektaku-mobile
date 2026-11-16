import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/accent_palette.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/features/settings/settings_summary.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';

import '../../support/screen_harness.dart';

Future<ScreenHarness> open(WidgetTester tester, {SettingsDto? stored}) async {
  final harness = ScreenHarness();
  if (stored != null) harness.settings.stored = stored;
  await harness.pump(
    tester,
    const SettingsPageScreen(page: SettingsPage.appearance),
    size: const Size(390, 1600),
  );
  return harness;
}

void main() {
  test('the summary names a matching preset or calls it custom', () {
    expect(appearanceSummary(defaultSettings), 'Kuning');
    expect(
      appearanceSummary(defaultSettings.copyWith(accent: '#3B82F6')),
      'Biru',
    );
    expect(
      appearanceSummary(defaultSettings.copyWith(accent: '#123456')),
      'Kustom',
    );
  });

  testWidgets('tapping a preset saves its hex and selects its dot', (
    tester,
  ) async {
    final harness = await open(tester);
    await tester.tap(find.byKey(const Key('swatch-#3B82F6')));
    await tester.pumpAndSettle();
    expect(harness.settings.saves.single.accent, '#3B82F6');
  });

  testWidgets('the reset button restores the default yellow', (tester) async {
    final harness = await open(
      tester,
      stored: defaultSettings.copyWith(accent: '#3B82F6'),
    );
    await tester.tap(find.byKey(const Key('appearance-reset')));
    await tester.pumpAndSettle();
    expect(
      harness.settings.saves.single.accent,
      accentToHex(defaultAccentColor),
    );
  });

  testWidgets('dragging the hue slider commits a new accent on release', (
    tester,
  ) async {
    final harness = await open(tester);
    await tester.drag(
      find.byKey(const Key('accent-hue-slider')),
      const Offset(80, 0),
    );
    await tester.pumpAndSettle();
    expect(harness.settings.saves, isNotEmpty);
    expect(parseAccentHex(harness.settings.saves.last.accent), isNotNull);
  });

  testWidgets('the preview card shows the sample button and link', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Tombol utama'), findsOneWidget);
    expect(find.text('Selengkapnya'), findsOneWidget);
  });
}
