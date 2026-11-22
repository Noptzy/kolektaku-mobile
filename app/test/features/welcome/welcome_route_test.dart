import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/welcome/welcome_gate.dart';
import 'package:kolektaku/features/welcome/welcome_providers.dart';
import 'package:kolektaku/features/welcome/welcome_store.dart';
import 'package:kolektaku/widgets/floating_dock.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/fake_catalog_gateway.dart';
import '../../support/fake_library_gateway.dart';
import '../../support/fake_settings_gateway.dart';
import '../../support/fake_source_gateway.dart';
import '../../support/fake_translation_gateway.dart';
import '../../widgets/widget_harness.dart';

class _Store implements WelcomeStore {
  int marks = 0;

  @override
  Future<bool> seen() async => marks > 0;

  @override
  Future<void> markSeen() async => marks++;
}

Future<_Store> _open(
  WidgetTester tester, {
  required WelcomeGate gate,
  String at = Routes.home,
}) async {
  tester.view.physicalSize = phoneLarge;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final store = _Store();
  await tester.pumpWidget(
    kolektakuScope(
      overrides: [
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
        libraryGatewayProvider.overrideWithValue(FakeLibraryGateway()),
        sourceGatewayProvider.overrideWithValue(FakeSourceGateway()),
        settingsGatewayProvider.overrideWithValue(FakeSettingsGateway()),
        translationGatewayProvider.overrideWithValue(FakeTranslationGateway()),
        welcomeStoreProvider.overrideWithValue(store),
        welcomeCoversProvider.overrideWith((ref) async => <String>[]),
      ],
      child: ShadApp.router(
        darkTheme: kolektakuDarkTheme(),
        themeMode: ThemeMode.dark,
        routerConfig: createRouter(initialLocation: at, gate: gate),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

void main() {
  testWidgets('a first launch lands on the welcome, not the home page', (
    tester,
  ) async {
    await _open(tester, gate: WelcomeGate(pending: true));
    expect(find.byKey(const Key('welcome-next')), findsOneWidget);
    expect(find.byType(FloatingDock), findsNothing);
  });

  testWidgets('after the first launch the home page opens straight away', (
    tester,
  ) async {
    await _open(tester, gate: WelcomeGate());
    expect(find.byKey(const Key('welcome-next')), findsNothing);
    expect(find.byType(FloatingDock), findsOneWidget);
  });

  testWidgets('skipping it opens the home page and does not come back', (
    tester,
  ) async {
    final gate = WelcomeGate(pending: true);
    final store = await _open(tester, gate: gate);
    await tester.tap(find.byKey(const Key('welcome-skip')));
    await tester.pumpAndSettle();
    expect(store.marks, 1);
    expect(find.byType(FloatingDock), findsOneWidget);
    expect(find.byKey(const Key('welcome-next')), findsNothing);
  });

  testWidgets('a deep link is not swallowed while the welcome is pending', (
    tester,
  ) async {
    await _open(
      tester,
      gate: WelcomeGate(pending: true),
      at: Routes.collection,
    );
    expect(find.byKey(const Key('welcome-next')), findsNothing);
    expect(find.byType(FloatingDock), findsOneWidget);
  });
}
