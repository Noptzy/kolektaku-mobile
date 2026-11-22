import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/features/welcome/welcome_gate.dart';
import 'package:kolektaku/features/welcome/welcome_providers.dart';
import 'package:kolektaku/features/welcome/welcome_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../widgets/widget_harness.dart';

const _sizes = {'390x844': phoneLarge, '360x780': phoneSmall};

Future<void> _open(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        welcomeCoversProvider.overrideWith((ref) async => <String>[]),
      ],
      child: ShadApp(
        darkTheme: kolektakuDarkTheme(),
        themeMode: ThemeMode.dark,
        home: WelcomeScreen(gate: WelcomeGate(pending: true)),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  _sizes.forEach((label, size) {
    testWidgets('welcome first page at $label', (tester) async {
      await _open(tester, size);
      await expectLater(
        find.byType(WelcomeScreen),
        matchesGoldenFile('goldens/welcome_first_$label.png'),
      );
    });

    testWidgets('welcome last page at $label', (tester) async {
      await _open(tester, size);
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('welcome-next')));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 100));
      await expectLater(
        find.byType(WelcomeScreen),
        matchesGoldenFile('goldens/welcome_last_$label.png'),
      );
    });
  });
}
