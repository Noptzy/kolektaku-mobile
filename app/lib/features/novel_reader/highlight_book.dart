import 'package:flutter/foundation.dart';

import '../../data/gateways/highlight_gateway.dart';
import '../../src/rust/dto/highlight.dart';
import '../../src/rust/dto/media.dart';
import 'highlight_ranges.dart';

class HighlightBook extends ChangeNotifier {
  HighlightBook({required this.gateway, required this.reference});

  final HighlightGateway gateway;
  final MediaRefDto reference;
  final Map<double, List<HighlightDto>> _byChapter = {};
  final Set<double> _asked = {};
  bool _disposed = false;

  List<HighlightDto> of(double chapter) => _byChapter[chapter] ?? const [];

  List<Marked> marksIn({
    required double chapter,
    required int block,
    required String text,
    required String language,
  }) {
    final marks = <Marked>[];
    for (final item in of(chapter)) {
      if (item.block != block || item.language != language) continue;
      final mark = locateMark(
        id: item.id,
        text: text,
        start: item.start,
        end: item.end,
        quote: item.quote,
      );
      if (mark != null) marks.add(mark);
    }
    return marks;
  }

  Future<void> load(double chapter) async {
    if (!_asked.add(chapter)) return;
    try {
      final found = await gateway.ofChapter(reference, chapter);
      if (_disposed) return;
      _byChapter[chapter] = found;
      notifyListeners();
    } on Object {
      _asked.remove(chapter);
    }
  }

  Future<void> add(HighlightInputDto input) async {
    await gateway.add(input);
    _asked.remove(input.chapter);
    await load(input.chapter);
  }

  Future<void> remove(int id, double chapter) async {
    await gateway.remove(id);
    _asked.remove(chapter);
    await load(chapter);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
