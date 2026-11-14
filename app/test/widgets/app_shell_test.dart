import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/widgets/app_bottom_bar.dart';
import 'package:kolektaku/widgets/option_chip.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/fake_catalog_gateway.dart';
import '../support/fake_library_gateway.dart';
import '../support/fake_settings_gateway.dart';
import '../support/fake_source_gateway.dart';
import 'widget_harness.dart';

Future<void> open(WidgetTester tester, {String at = '/beranda'}) async {
  tester.view.physicalSize = phoneLarge;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    kolektakuScope(
      overrides: [
        catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
        libraryGatewayProvider.overrideWithValue(FakeLibraryGateway()),
        sourceGatewayProvider.overrideWithValue(FakeSourceGateway()),
        settingsGatewayProvider.overrideWithValue(FakeSettingsGateway()),
      ],
      child: ShadApp.router(
        darkTheme: kolektakuDarkTheme(),
        themeMode: ThemeMode.dark,
        routerConfig: createRouter(initialLocation: at),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder bar(String label) =>
    find.descendant(of: find.byType(AppBottomBar), matching: find.text(label));

int currentTab(WidgetTester tester) =>
    tester.widget<AppBottomBar>(find.byType(AppBottomBar)).currentIndex;

void main() {
  testWidgets('starts on the home page with four destinations', (tester) async {
    await open(tester);
    expect(find.text('Kolektaku'), findsNothing);
    expect(bar('Beranda'), findsOneWidget);
    expect(bar('Cari'), findsOneWidget);
    expect(bar('Koleksi'), findsOneWidget);
    expect(bar('Pengaturan'), findsOneWidget);
    expect(
      tester
          .widget<AppBottomBar>(find.byType(AppBottomBar))
          .destinations
          .length,
      4,
    );
  });

  testWidgets('the root path lands on the home page', (tester) async {
    await open(tester, at: '/');
    expect(currentTab(tester), 0);
  });

  testWidgets('tapping each destination switches the screen', (tester) async {
    await open(tester);
    for (final (index, label) in [
      (1, 'Cari'),
      (2, 'Koleksi'),
      (3, 'Pengaturan'),
      (0, 'Beranda'),
    ]) {
      await tester.tap(bar(label));
      await tester.pumpAndSettle();
      expect(currentTab(tester), index, reason: label);
    }
  });

  testWidgets('search is its own tab, without scope buttons', (tester) async {
    await open(tester);
    expect(find.text('Cari anime, komik, karakter, studio'), findsNothing);
    await tester.tap(bar('Cari'));
    await tester.pumpAndSettle();
    expect(find.text('Cari anime, komik, karakter, studio'), findsOneWidget);
    for (final scope in ['Komik', 'Karakter', 'Staf', 'Studio']) {
      expect(find.widgetWithText(OptionChip, scope), findsNothing);
    }
  });

  testWidgets('the settings tab shows the settings screen', (tester) async {
    await open(tester);
    await tester.tap(bar('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan'), findsWidgets);
    expect(find.byKey(const Key('settings-row-beranda')), findsOneWidget);
    expect(find.text('Lebih banyak anime'), findsOneWidget);
  });

  testWidgets('system back from another tab returns to the home page first', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(bar('Koleksi'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(currentTab(tester), 0);
  });

  testWidgets('every destination is at least 48 dp and announced', (
    tester,
  ) async {
    await open(tester);
    for (final label in ['Beranda', 'Cari', 'Koleksi', 'Pengaturan']) {
      final size = tester.getSize(
        find.ancestor(of: bar(label), matching: find.byType(GestureDetector)),
      );
      expect(size.height, greaterThanOrEqualTo(48), reason: label);
      expect(size.width, greaterThanOrEqualTo(48), reason: label);
    }
    final selected = tester.getSemantics(
      find.ancestor(of: bar('Beranda'), matching: find.byType(GestureDetector)),
    );
    expect(selected.hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(selected.hasFlag(SemanticsFlag.isButton), isTrue);
  });

  testWidgets('the watch screen route is outside the shell', (tester) async {
    final router = createRouter();
    expect(
      router.configuration.routes.whereType<GoRoute>().any(
        (route) => route.path == '/watch',
      ),
      isTrue,
    );
  });
}
