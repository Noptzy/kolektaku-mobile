import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';

import '../../support/screen_harness.dart';

void main() {
  testWidgets('the about page can show the welcome again', (tester) async {
    final harness = ScreenHarness();
    await harness.pump(
      tester,
      const SettingsPageScreen(page: SettingsPage.about),
    );
    expect(find.text('Sambutan'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('about-welcome')));
    await tester.tap(find.byKey(const Key('about-welcome')));
    await tester.pumpAndSettle();
    expect(harness.visits.last.path, Routes.welcome);
  });

  testWidgets('the button is labelled in Indonesian and reachable', (
    tester,
  ) async {
    await ScreenHarness().pump(
      tester,
      const SettingsPageScreen(page: SettingsPage.about),
    );
    expect(find.text('Lihat sambutan'), findsOneWidget);
    final size = tester.getSize(find.byKey(const Key('about-welcome')));
    expect(size.height, greaterThanOrEqualTo(40));
  });
}
