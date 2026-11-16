import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/features/settings/settings_summary.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';

import '../../support/screen_harness.dart';

Future<ScreenHarness> open(WidgetTester tester) async {
  final harness = ScreenHarness();
  await harness.pump(
    tester,
    const SettingsPageScreen(page: SettingsPage.reader),
    size: const Size(390, 900),
  );
  return harness;
}

void main() {
  testWidgets('continuing into the next chapter is on and can be turned off', (
    tester,
  ) async {
    final harness = await open(tester);
    expect(find.text('Pembaca'), findsOneWidget);
    await tester.tap(find.text('Lanjut otomatis ke chapter berikutnya'));
    await tester.pumpAndSettle();
    expect(harness.settings.saves.last.continuousReading, isFalse);
  });

  test('the summary says which way chapters flow', () {
    expect(readerSummary(defaultSettings), 'Chapter tersambung otomatis');
    expect(
      readerSummary(defaultSettings.copyWith(continuousReading: false)),
      'Pilih chapter berikutnya sendiri',
    );
  });
}
