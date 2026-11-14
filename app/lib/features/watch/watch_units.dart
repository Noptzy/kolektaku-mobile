import 'package:flutter/foundation.dart';

import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import 'episode_loader.dart';

class WatchUnits {
  WatchUnits({required this.loader, required this.onChange});

  final EpisodeLoader loader;
  final VoidCallback onChange;

  List<UnitDto> list = const [];
  int _token = 0;
  String? _source;
  bool _closed = false;

  bool needs(String playing) {
    if (list.isEmpty) return true;
    final asked = _source;
    return asked != null && asked != playing;
  }

  Future<void> load(MediaRefDto reference, String? source) async {
    final token = ++_token;
    _source = source;
    final result = await loader.unitsOrEmpty(reference, source: source);
    if (token != _token || _closed) return;
    if (result.isEmpty && list.isNotEmpty) return;
    list = result;
    onChange();
  }

  void close() => _closed = true;
}
