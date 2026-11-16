import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../src/rust/dto/sources.dart';
import '../../src/rust/dto/stream.dart';
import '../detail/episode_window.dart';
import 'chapter_loader.dart';
import 'read_progress.dart';
import 'read_request.dart';

part 'reader_controller_stack.dart';

class ReaderController extends ChangeNotifier {
  ReaderController({
    required this.request,
    required this.loader,
    required this.progress,
    this.saveDelay = const Duration(seconds: 1),
    this.autoContinue = true,
  });

  final ChapterLoader loader;
  final ReadProgress progress;
  final Duration saveDelay;
  final bool autoContinue;

  ReadRequest request;
  List<ChapterViewDto> chapters = const [];
  int visible = 0;
  Object? error;
  Object? extendError;
  bool extending = false;
  int connected = 0;
  List<UnitDto> units = const [];
  int page = 0;
  int startPage = 0;
  int _generation = 0;
  int _unitsToken = 0;
  String? _unitsSource;
  Timer? _saveTimer;
  bool _dirty = false;
  bool _disposed = false;

  ChapterViewDto? get view => chapters.isEmpty ? null : chapters[visible];

  double get current => view?.unit.number ?? request.chapter;

  int get total => view?.pages.length ?? 0;

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
    page = 0;
    startPage = 0;
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
      final resume = await _resume(opened.unit.number);
      if (generation != _generation) return;
      final last = opened.pages.length - 1;
      startPage = last < 0 ? 0 : (resume ?? 0).clamp(0, last).toInt();
      page = startPage;
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
      return await progress.resumePage(request, chapter);
    } on Object {
      return null;
    }
  }

  Future<void> goTo(UnitDto unit) {
    request = request.copyWith(chapter: unit.number);
    return load();
  }

  Future<void> tryOtherSource() {
    final source = view?.source;
    return load(exclude: source == null ? const [] : [source]);
  }

  void onPage(int index) {
    final last = total - 1;
    if (last < 0) return;
    final clamped = index.clamp(0, last).toInt();
    if (clamped == page) return;
    page = clamped;
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, flush);
    _notify();
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    final opened = view;
    if (!_dirty || opened == null) return;
    _dirty = false;
    await _save(opened, page);
  }

  Future<void> _save(ChapterViewDto chapter, int at) async {
    try {
      await progress.save(
        request,
        chapter.unit.number,
        page: at + 1,
        total: chapter.pages.length,
      );
    } on Object {
      return;
    }
  }

  bool _needsUnits(String playing) {
    if (units.isEmpty) return true;
    final asked = _unitsSource;
    return asked != null && asked != playing;
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
