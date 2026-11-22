import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderContainer;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/data/providers/download_providers.dart';
import 'package:kolektaku/widgets/swipe_toast_host.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';
import 'package:kolektaku/features/home/hero_auto_play.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'fake_catalog_gateway.dart';
import 'fake_download_gateway.dart';
import 'fake_highlight_gateway.dart';
import 'fake_library_gateway.dart';
import 'fake_settings_gateway.dart';
import 'fake_source_gateway.dart';
import 'fake_translation_gateway.dart';

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
    FakeTranslationGateway? translation,
    FakeHighlightGateway? highlights,
  }) : catalog = catalog ?? FakeCatalogGateway(),
       library = library ?? FakeLibraryGateway(),
       sources = sources ?? FakeSourceGateway(),
       settings = settings ?? FakeSettingsGateway(),
       translation = translation ?? FakeTranslationGateway(),
       highlights = highlights ?? FakeHighlightGateway();

  final FakeCatalogGateway catalog;
  final FakeLibraryGateway library;
  final FakeSourceGateway sources;
  final FakeSettingsGateway settings;
  final FakeTranslationGateway translation;
  final FakeHighlightGateway highlights;
  final FakeDownloadGateway downloads = FakeDownloadGateway();
  final FakeDownloadDevice device = FakeDownloadDevice();
  final List<Visit> visits = [];

  static const _stubs = [
    Routes.genres,
    Routes.genre,
    Routes.detail,
    Routes.profile,
    Routes.watch,
    Routes.read,
    Routes.novel,
    Routes.settings,
    Routes.settingsPage,
    Routes.search,
    Routes.sceneSearch,
    Routes.downloads,
    Routes.welcome,
  ];

  List<Override> get overrides => [
    catalogGatewayProvider.overrideWithValue(catalog),
    libraryGatewayProvider.overrideWithValue(library),
    sourceGatewayProvider.overrideWithValue(sources),
    settingsGatewayProvider.overrideWithValue(settings),
    translationGatewayProvider.overrideWithValue(translation),
    highlightGatewayProvider.overrideWithValue(highlights),
    heroAutoPlayProvider.overrideWithValue(null),
    downloadGatewayProvider.overrideWithValue(downloads),
    downloadDeviceProvider.overrideWithValue(device),
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
          builder: (context, child) =>
              SwipeToastHost(dismissOn: router.routerDelegate, child: child!),
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
