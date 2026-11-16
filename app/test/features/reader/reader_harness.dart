import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/theme/kolektaku_theme.dart';
import 'package:kolektaku/features/reader/chapter_loader.dart';
import 'package:kolektaku/features/reader/read_progress.dart';
import 'package:kolektaku/features/reader/read_request.dart';
import 'package:kolektaku/features/reader/reader_screen.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/decode.dart';
import '../../support/tiny_image.dart';

final reference = MediaRefDto(
  kind: MediaRefKind.catalog,
  id: BigInt.from(87216),
  source: '',
  item: '',
);

class FakeReadProgress implements ReadProgress {
  FakeReadProgress({this.resume});

  int? resume;
  final List<({double chapter, int page, int total})> saved = [];

  @override
  Future<int?> resumePage(ReadRequest request, double chapter) async => resume;

  @override
  Future<void> save(
    ReadRequest request,
    double chapter, {
    required int page,
    required int total,
  }) async => saved.add((chapter: chapter, page: page, total: total));
}

class ReaderHarness {
  ReaderHarness({
    this.pageCount = 5,
    this.unitCount = 4,
    this.chapter = 1,
    this.resume,
    this.failFirst = false,
    this.switchedFrom,
    this.hold,
    this.failOn,
  });

  final int pageCount;
  final int unitCount;
  final double chapter;
  final int? resume;
  final bool failFirst;
  final String? switchedFrom;
  final Completer<void>? hold;
  double? failOn;
  final List<double> opened = [];
  final List<List<String>> excluded = [];
  late final FakeReadProgress progress = FakeReadProgress(resume: resume);
  int loads = 0;

  ChapterLoader get loader => ChapterLoader(
    open:
        ({
          required MediaRefDto reference,
          required double chapter,
          String? preferred,
          required List<String> exclude,
        }) async {
          loads++;
          opened.add(chapter);
          excluded.add(List.of(exclude));
          await hold?.future;
          if (failFirst && loads == 1) throw StateError('no source');
          if (failOn == chapter) throw StateError('no chapter');
          return ChapterViewDto(
            source: 'k',
            item: 'k-item',
            unit: UnitDto(
              id: 'c$chapter',
              number: chapter,
              label: 'Chapter $chapter',
            ),
            pages: [
              for (var i = 1; i <= pageCount; i++)
                'https://img.test/c$chapter/$i.jpg',
            ],
            switchedFrom: switchedFrom,
          );
        },
    units: ({required MediaRefDto reference, String? source}) async => UnitsDto(
      source: source ?? 'k',
      item: 'k-item',
      units: [
        for (var i = 1; i <= unitCount; i++)
          UnitDto(id: 'c$i', number: i.toDouble(), label: 'Chapter $i'),
      ],
    ),
  );

  Widget app({
    Duration saveDelay = const Duration(milliseconds: 200),
    bool autoContinue = true,
  }) {
    return ShadApp(
      darkTheme: kolektakuDarkTheme(),
      themeMode: ThemeMode.dark,
      home: ReaderScreen(
        request: ReadRequest(
          reference: reference,
          title: 'Chainsaw Man',
          chapter: chapter,
        ),
        loader: loader,
        progress: progress,
        imageFor: (url, width) => MemoryImage(tinyPng),
        saveDelay: saveDelay,
        autoContinue: autoContinue,
      ),
    );
  }

  Future<void> open(WidgetTester tester, {bool autoContinue = true}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(autoContinue: autoContinue));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await decoded(tester);
  }
}
