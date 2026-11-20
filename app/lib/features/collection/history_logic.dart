import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../home/resume_card.dart';
import '../watch/player/clock_format.dart';

const historyVisibleRows = 5.5;

String historyKey(ProgressDto item) {
  final reference = item.reference;
  return '${reference.kind.name}:${reference.id}:${reference.source}:'
      '${reference.item}:${item.unitNumber}';
}

String _folded(String text) => text.toLowerCase().trim();

List<ProgressDto> filterHistory(List<ProgressDto> items, String query) {
  final wanted = _folded(query);
  if (wanted.isEmpty) return items;
  return [
    for (final item in items)
      if (_folded(item.title).contains(wanted) ||
          _folded(resumeMeta(item.kind, item.unitNumber)).contains(wanted))
        item,
  ];
}

double historyProgress(ProgressDto item) {
  if (item.completed) return 1;
  if (item.length <= 0) return 0;
  return (item.position / item.length).clamp(0.0, 1.0);
}

String historyPercent(ProgressDto item) =>
    '${(historyProgress(item) * 100).round()}%';

Duration _seconds(double value) =>
    Duration(milliseconds: (value * 1000).round());

String historyTimeLabel(ProgressDto item) {
  if (item.kind != MediaKindDto.anime || item.length <= 0) {
    return historyPercent(item);
  }
  if (item.completed) return 'Selesai';
  return '${formatClock(_seconds(item.position))} / '
      '${formatClock(_seconds(item.length))}';
}

String historySearchHint(MediaKindDto kind) => kind == MediaKindDto.anime
    ? 'Cari riwayat tontonan…'
    : 'Cari riwayat bacaan…';

String historyNoMatch(String query) =>
    'Tidak ada riwayat yang cocok dengan "$query".';
