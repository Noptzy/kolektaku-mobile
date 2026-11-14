import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/features/scene_search/share_listener.dart';
import 'package:kolektaku/platform/shared_image.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/fake_scene_gateway.dart';
import '../../support/tiny_image.dart';

Future<(GoRouter, List<Object?>)> open(
  WidgetTester tester,
  FakeSharedImages shared,
) async {
  final pushed = <Object?>[];
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const Text('beranda')),
      GoRoute(
        path: Routes.sceneSearch,
        builder: (context, state) {
          pushed.add(state.extra);
          return const Text('cari gambar');
        },
      ),
    ],
  );
  await tester.pumpWidget(
    kolektakuScope(
      overrides: [sharedImagesProvider.overrideWithValue(shared)],
      child: ShadApp.router(
        darkTheme: kolektakuDarkTheme(),
        themeMode: ThemeMode.dark,
        routerConfig: router,
        builder: (context, child) =>
            ShareListener(router: router, child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (router, pushed);
}

void main() {
  testWidgets('a picture shared before the app opened goes to image search', (
    tester,
  ) async {
    final (_, pushed) = await open(tester, FakeSharedImages(tinyPng));
    expect(find.text('cari gambar'), findsOneWidget);
    expect(pushed.single, tinyPng);
  });

  testWidgets('nothing shared leaves the app where it is', (tester) async {
    final shared = FakeSharedImages();
    final (_, pushed) = await open(tester, shared);
    expect(find.text('beranda'), findsOneWidget);
    expect(pushed, isEmpty);
    expect(shared.takes, 1);
  });

  testWidgets('coming back to the app checks for a newly shared picture', (
    tester,
  ) async {
    final shared = FakeSharedImages();
    final (_, pushed) = await open(tester, shared);
    shared.image = tinyPng;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(pushed.single, tinyPng);
    expect(shared.takes, 2);
  });

  testWidgets('the same picture is not opened twice', (tester) async {
    final shared = FakeSharedImages(tinyPng);
    final (_, pushed) = await open(tester, shared);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(pushed.length, 1);
  });

  group('ChannelSharedImages', () {
    const channel = MethodChannel(ChannelSharedImages.channelName);

    void reply(Future<Object?>? Function(MethodCall call) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, handler);
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
    }

    test('asks the platform for the shared picture', () async {
      String? asked;
      reply((call) async {
        asked = call.method;
        return tinyPng;
      });
      final bytes = await const ChannelSharedImages().take();
      expect(asked, 'takeSharedImage');
      expect(bytes, tinyPng);
    });

    test('no shared picture comes back as null', () async {
      reply((call) async => null);
      expect(await const ChannelSharedImages().take(), isNull);
    });

    test('a platform error is treated as nothing shared', () async {
      reply((call) async => throw PlatformException(code: 'x'));
      expect(await const ChannelSharedImages().take(), isNull);
    });

    test('a missing platform plugin is treated as nothing shared', () async {
      reply((call) async => throw MissingPluginException());
      expect(await const ChannelSharedImages().take(), isNull);
    });
  });
}
