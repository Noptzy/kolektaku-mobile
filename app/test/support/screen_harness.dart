import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'fake_catalog_gateway.dart';
import 'fake_library_gateway.dart';
import 'fake_settings_gateway.dart';
import 'fake_source_gateway.dart';

class Visit {
  const Visit(this.path, this.extra);

  final String path;
  final Object? extra;
}

class ScreenHarness {
  ScreenHarness({
    FakeCatalogGateway? catalog,
    FakeLibraryGateway? library,
    FakeSourceGateway? sources,
    FakeSettingsGateway? settings,
  }) : catalog = catalog ?? FakeCatalogGateway(),
       library = library ?? FakeLibraryGateway(),
       sources = sources ?? FakeSourceGateway(),
       settings = settings ?? FakeSettingsGateway();

  final FakeCatalogGateway catalog;
  final FakeLibraryGateway library;
  final FakeSourceGateway sources;
  final FakeSettingsGateway settings;
  final List<Visit> visits = [];

  static const _stubs = [
    Routes.genres,
    Routes.genre,
    Routes.detail,
    Routes.profile,
    Routes.watch,
    Routes.read,
    Routes.settings,
    Routes.settingsPage,
    Routes.search,
    Routes.sceneSearch,
  ];

  List<Override> get overrides => [
    catalogGatewayProvider.overrideWithValue(catalog),
    libraryGatewayProvider.overrideWithValue(library),
    sourceGatewayProvider.overrideWithValue(sources),
    settingsGatewayProvider.overrideWithValue(settings),
  ];

  ProviderContainer container() => ProviderContainer(overrides: overrides);

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(390, 844),
    List<Override> extra = const [],
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => screen),
        for (final path in _stubs)
          GoRoute(
            path: path,
            builder: (context, state) {
              visits.add(Visit(state.uri.path, state.extra));
              return Text('stub:$path');
            },
          ),
      ],
    );
    await tester.pumpWidget(
      kolektakuScope(
        overrides: [...overrides, ...extra],
        child: ShadApp.router(
          darkTheme: kolektakuDarkTheme(),
          themeMode: ThemeMode.dark,
          routerConfig: router,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    } else {
      await tester.pump();
    }
  }
}
