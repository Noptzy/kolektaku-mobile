import 'dart:typed_data';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/features/novel_reader/novel_blocks.dart';
import 'package:kolektaku/src/rust/dto/novel.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/tiny_image.dart';

Widget host(NovelBlockDto block, {NovelImageFactory? imageFor}) => ShadApp(
  darkTheme: kolektakuDarkTheme(),
  themeMode: ThemeMode.dark,
  home: Builder(
    builder: (context) => ListView(
      children: [
        NovelBlock(
          block: block,
          size: ReadingSizeDto.medium,
          spacing: ReadingSpacingDto.normal,
          imageFor: imageFor ?? (url) => MemoryImage(tinyPng),
        ),
        const Text('Paragraf sesudahnya.'),
      ],
    ),
  ),
);

void main() {
  testWidgets('an illustration block shows the picture between paragraphs', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const NovelBlockDto(isImage: true, text: 'https://cdn.test/a.jpg')),
    );
    await tester.pump();
    expect(find.byKey(const Key('illustration')), findsOneWidget);
    expect(find.text('Paragraf sesudahnya.'), findsOneWidget);
  });

  testWidgets('tapping the picture opens it large and it can be closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const NovelBlockDto(isImage: true, text: 'https://cdn.test/a.jpg')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('illustration')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('illustration-large')), findsOneWidget);
    await tester.tap(find.byKey(const Key('illustration-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('illustration-large')), findsNothing);
  });

  testWidgets('a picture that fails to load leaves a small note and the text', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const NovelBlockDto(isImage: true, text: 'https://cdn.test/broken.jpg'),
        imageFor: (url) => MemoryImage(Uint8List.fromList([1, 2, 3])),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Gambar tidak bisa dimuat.'), findsOneWidget);
    expect(find.text('Paragraf sesudahnya.'), findsOneWidget);
  });
}
