import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/novel_reader/novel_loader.dart';
import 'package:kolektaku/features/novel_reader/novel_progress.dart';
import 'package:kolektaku/features/novel_reader/novel_request.dart';
import 'package:kolektaku/features/novel_reader/novel_screen.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/novel.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import '../../support/fake_highlight_gateway.dart';
import '../../support/screen_harness.dart';

final reference = MediaRefDto(
  kind: MediaRefKind.catalog,
  id: BigInt.from(87216),
  source: '',
  item: '',
);

class FakeNovelProgress implements NovelProgress {
  FakeNovelProgress({this.resume});

  int? resume;
  final List<({double chapter, int block, int total})> saved = [];

  @override
  Future<int?> resumeBlock(NovelRequest request, double chapter) async =>
      resume;

  @override
  Future<void> save(
    NovelRequest request,
    double chapter, {
    required int block,
    required int total,
  }) async => saved.add((chapter: chapter, block: block, total: total));
}

NovelBlockDto paragraph(String text) =>
    NovelBlockDto(isImage: false, text: text);

class NovelHarness {
  NovelHarness({
    this.blockCount = 40,
    this.unitCount = 4,
    this.chapter = 1,
    this.resume,
    this.translated = false,
    this.failFirst = false,
    this.translationFailed = false,
    this.switchedFrom,
    FakeHighlightGateway? highlights,
  }) : highlights = highlights ?? FakeHighlightGateway();

  final FakeHighlightGateway highlights;
  final int blockCount;
  final int unitCount;
  final double chapter;
  final int? resume;
  final bool translated;
  final bool failFirst;
  final bool translationFailed;
  final String? switchedFrom;
  final List<double> opened = [];
  final List<double> preloaded = [];
  final List<List<String>> excluded = [];
  late final FakeNovelProgress progress = FakeNovelProgress(resume: resume);
  int loads = 0;

  List<NovelBlockDto> _blocks(String prefix) => [
    for (var i = 1; i <= blockCount; i++)
      paragraph('$prefix paragraf $i. ${'Kalimat panjang. ' * 6}'),
  ];

  NovelLoader get loader => NovelLoader(
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
          if (failFirst && loads == 1) throw StateError('no source');
          return NovelChapterDto(
            source: 'n',
            item: 'n-item',
            unit: UnitDto(
              id: 'c$chapter',
              number: chapter,
              label: 'Chapter $chapter',
            ),
            language: translated ? 'en' : 'id',
            blocks: _blocks('Asli'),
            translatedLanguage: translated ? 'id' : null,
            translatedBlocks: translated ? _blocks('Terjemahan') : const [],
            translationFailed: translationFailed,
            switchedFrom: switchedFrom,
          );
        },
    preload:
        ({
          required MediaRefDto reference,
          required double chapter,
          String? preferred,
        }) async {
          preloaded.add(chapter);
          return true;
        },
    units: ({required MediaRefDto reference, String? source}) async => UnitsDto(
      source: source ?? 'n',
      item: 'n-item',
      units: [
        for (var i = 1; i <= unitCount; i++)
          UnitDto(id: 'c$i', number: i.toDouble(), label: 'Chapter $i'),
      ],
    ),
  );

  NovelScreen screen({
    Duration saveDelay = const Duration(milliseconds: 200),
    bool autoContinue = true,
  }) {
    return NovelScreen(
      request: NovelRequest(
        reference: reference,
        title: 'Mushoku Tensei',
        chapter: chapter,
      ),
      loader: loader,
      progress: progress,
      saveDelay: saveDelay,
      autoContinue: autoContinue,
    );
  }

  Future<ScreenHarness> open(
    WidgetTester tester, {
    bool autoContinue = true,
  }) async {
    final harness = ScreenHarness(highlights: highlights);
    await harness.pump(
      tester,
      screen(autoContinue: autoContinue),
      settle: false,
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return harness;
  }
}
