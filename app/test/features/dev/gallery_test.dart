import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/features/dev/gallery/gallery_screen.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void main() {
  testWidgets('the gallery lists the color and type tokens', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        darkTheme: kolektakuDarkTheme(),
        themeMode: ThemeMode.dark,
        home: const GalleryScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('Galeri komponen'), findsOneWidget);
    expect(find.text('Warna'), findsOneWidget);
    expect(find.text('Huruf'), findsOneWidget);
    expect(find.text('utama'), findsOneWidget);
    expect(find.text('Kimi no Na wa.'), findsOneWidget);
  });
}
