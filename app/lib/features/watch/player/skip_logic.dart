import '../../../src/rust/dto/stream_extras.dart';

const _leadIn = 500;
const _tail = 250;

bool _inside(SkipDto range, int at) =>
    at >= range.startMs.toInt() - _leadIn && at < range.endMs.toInt() - _tail;

SkipDto? activeSkip(List<SkipDto> skips, Duration position) {
  final at = position.inMilliseconds;
  for (final range in skips) {
    if (_inside(range, at)) return range;
  }
  return null;
}

List<(double, double)> skipFractions(List<SkipDto> skips, Duration duration) {
  final total = duration.inMilliseconds;
  if (total <= 0) return const [];
  final spans = <(double, double)>[];
  for (final range in skips) {
    final start = (range.startMs.toInt() / total).clamp(0.0, 1.0);
    final end = (range.endMs.toInt() / total).clamp(0.0, 1.0);
    if (end > start) spans.add((start, end));
  }
  return spans;
}

String skipKey(SkipDto range) =>
    '${range.kind}-${range.startMs}-${range.endMs}';

String skipLabel(SkipDto range) =>
    range.kind == 'outro' ? 'Lewati outro' : 'Lewati intro';

Duration skipTarget(SkipDto range) =>
    Duration(milliseconds: range.endMs.toInt());
