import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/features/reader/page_image.dart';
import 'package:kolektaku/widgets/pressable.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/decode.dart';
import '../../support/tiny_image.dart';

class FlakyImage extends ImageProvider<FlakyImage> {
  FlakyImage({this.failures = 1});

  final int failures;
  int attempts = 0;

  @override
  Future<FlakyImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(FlakyImage key, ImageDecoderCallback decode) {
    attempts++;
    if (attempts <= failures) {
      return OneFrameImageStreamCompleter(Future.error(StateError('down')));
    }
    return MultiFrameImageStreamCompleter(
      codec: ui.instantiateImageCodec(tinyPng),
      scale: 1,
    );
  }
}

Widget host(PageImage image) => ShadApp(
  darkTheme: kolektakuDarkTheme(),
  themeMode: ThemeMode.dark,
  home: Center(child: SizedBox(width: 200, child: image)),
);

void main() {
  testWidgets('a loaded picture is as tall as its own shape', (tester) async {
    double? reported;
    await tester.pumpWidget(
      host(
        PageImage(
          provider: MemoryImage(tinyPng),
          aspect: 0.7,
          onAspect: (aspect) => reported = aspect,
        ),
      ),
    );
    await decoded(tester, until: () => reported != null);
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.getSize(find.byType(PageImage)).height, 200);
    expect(reported, 1.0);
  });

  testWidgets('before it loads the placeholder keeps the given shape', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        PageImage(
          provider: FlakyImage(failures: 99),
          aspect: 0.5,
          onAspect: (_) {},
        ),
      ),
    );
    expect(tester.getSize(find.byType(PageImage)).height, 400);
    expect(find.byType(RawImage), findsNothing);
  });

  testWidgets('a failed picture offers a retry that loads it again', (
    tester,
  ) async {
    final provider = FlakyImage();
    await tester.pumpWidget(
      host(PageImage(provider: provider, aspect: 0.7, onAspect: (_) {})),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('page-retry')), findsOneWidget);
    expect(find.byType(RawImage), findsNothing);
    await tester.tap(find.byType(Pressable));
    await tester.pump();
    await decoded(tester);
    expect(provider.attempts, 2);
    expect(find.byType(RawImage), findsOneWidget);
    expect(find.byKey(const Key('page-retry')), findsNothing);
  });

  testWidgets('a new provider replaces the picture', (tester) async {
    final first = FlakyImage(failures: 0);
    final second = FlakyImage(failures: 0);
    await tester.pumpWidget(
      host(PageImage(provider: first, aspect: 0.7, onAspect: (_) {})),
    );
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(
      host(PageImage(provider: second, aspect: 0.7, onAspect: (_) {})),
    );
    await tester.pump();
    await decoded(tester);
    expect(second.attempts, 1);
    expect(find.byType(RawImage), findsOneWidget);
  });

  testWidgets('leaving the screen disposes without a report', (tester) async {
    var reports = 0;
    await tester.pumpWidget(
      host(
        PageImage(
          provider: FlakyImage(failures: 0),
          aspect: 0.7,
          onAspect: (_) => reports++,
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(reports, 0);
  });

  test('network pages are decoded no wider than the screen', () {
    final plain = networkPageImage('https://img.test/a.jpg', null);
    expect(plain, isA<NetworkImage>());
    final resized = networkPageImage('https://img.test/a.jpg', 800);
    expect(resized, isA<ResizeImage>());
    expect((resized as ResizeImage).width, 800);
    expect(resized.allowUpscaling, isFalse);
  });
}
