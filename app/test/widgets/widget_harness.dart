import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const phoneLarge = Size(390, 844);
const phoneSmall = Size(360, 780);

Future<void> pumpAtSize(
  WidgetTester tester,
  Widget child, {
  Size size = phoneLarge,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ShadApp(
      darkTheme: kolektakuDarkTheme(),
      themeMode: ThemeMode.dark,
      home: ColoredBox(
        color: kolektakuDarkTheme().colorScheme.background,
        child: SafeArea(child: child),
      ),
    ),
  );
  await tester.pump();
}
