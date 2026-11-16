import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../src/rust/dto/novel.dart';
import '../../src/rust/dto/sources.dart';
import '../detail/episode_window.dart';
import '../reader/reader_controller.dart' show DividerKind;
import 'novel_loader.dart';
import 'novel_progress.dart';
import 'novel_request.dart';

part 'novel_controller_navigation.dart';
part 'novel_controller_stack.dart';

const preloadFrom = 0.7;
const maxConnectedNovelChapters = 5;

class NovelController extends ChangeNotifier {
  NovelController({
    required this.request,
    required this.loader,
    required this.progress,
    this.saveDelay = const Duration(seconds: 1),
    this.autoContinue = true,
  });

  final NovelLoader loader;
  final NovelProgress progress;
  final Duration saveDelay;
  final bool autoContinue;

  NovelRequest request;
  List<NovelChapterDto> chapters = const [];
  int visible = 0;
  Object? error;
  Object? extendError;
  bool extending = false;
  int connected = 0;
  List<UnitDto> units = const [];
  int block = 0;
  int startBlock = 0;
  bool showOriginal = false;
  int _generation = 0;
  int _unitsToken = 0;
  String? _unitsSource;
  Timer? _saveTimer;
  bool _dirty = false;
  bool _preloaded = false;
  bool _disposed = false;

  NovelChapterDto? get view => chapters.isEmpty ? null : chapters[visible];

  double get current => view?.unit.number ?? request.chapter;

  bool get hasTranslation => view?.translatedBlocks.isNotEmpty ?? false;

  bool get translationFailed => view?.translationFailed ?? false;

  List<NovelBlockDto> blocksOf(int chapter) {
    final opened = chapters[chapter];
    final translated = opened.translatedBlocks.isNotEmpty && !showOriginal;
    return translated ? opened.translatedBlocks : opened.blocks;
  }

  List<NovelBlockDto> get blocks =>
      chapters.isEmpty ? const [] : blocksOf(visible);

  int get total => blocks.length;

  UnitDto? get next => unitAfter(units, current);

  UnitDto? get previous => unitBefore(units, current);

  Future<void> load({List<String> exclude = const []}) async {
    final generation = ++_generation;
    await flush();
    error = null;
    extendError = null;
    extending = false;
    connected = 0;
    visible = 0;
    chapters = const [];
    block = 0;
    startBlock = 0;
    _preloaded = false;
    _notify();
    if (units.isEmpty) unawaited(_loadUnits(request.preferredSource));
    try {
      final opened = await loader.open(
        request.reference,
        request.chapter,
        preferred: request.preferredSource,
        exclude: exclude,
      );
      if (generation != _generation) return;
      final resume = request.block ?? await _resume(opened.unit.number);
      if (generation != _generation) return;
      final last = opened.blocks.length - 1;
      startBlock = last < 0 ? 0 : (resume ?? 0).clamp(0, last).toInt();
      block = startBlock;
      chapters = [opened];
      _notify();
      if (_needsUnits(opened.source)) unawaited(_loadUnits(opened.source));
    } on Object catch (failure) {
      if (generation != _generation || _disposed) return;
      error = failure;
      _notify();
    }
  }

  Future<int?> _resume(double chapter) async {
    try {
      return await progress.resumeBlock(request, chapter);
    } on Object {
      return null;
    }
  }

  void onBlock(int index) {
    final last = total - 1;
    if (last < 0) return;
    final clamped = index.clamp(0, last).toInt();
    if (clamped == block) return;
    block = clamped;
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, flush);
    _maybePreload(clamped / last);
    _notify();
  }

  void _maybePreload(double fraction) {
    final opened = view;
    final target = next;
    if (_preloaded || opened == null || target == null) return;
    if (fraction < preloadFrom || autoContinue) return;
    _preloaded = true;
    unawaited(
      loader.preload(
        request.reference,
        target.number,
        preferred: opened.source,
      ),
    );
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final opened = view;
    if (!_dirty || opened == null) return;
    _dirty = false;
    await _save(opened, block);
  }

  Future<void> _save(NovelChapterDto chapter, int at) async {
    try {
      await progress.save(
        request,
        chapter.unit.number,
        block: at + 1,
        total: chapter.blocks.length,
      );
    } on Object {
      return;
    }
  }

  bool _needsUnits(String reading) {
    if (units.isEmpty) return true;
    final asked = _unitsSource;
    return asked != null && asked != reading;
  }

  Future<void> _loadUnits(String? source) async {
    final token = ++_unitsToken;
    _unitsSource = source;
    final result = await loader.unitsOrEmpty(request.reference, source: source);
    if (token != _unitsToken || _disposed) return;
    if (result.isEmpty && units.isNotEmpty) return;
    units = result;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    unawaited(flush());
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
