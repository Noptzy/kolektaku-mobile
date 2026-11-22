import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';

const _secondsPerMinute = 60;

String agoLabel(DateTime now, BigInt updatedAtSecs) {
  final then = DateTime.fromMillisecondsSinceEpoch(
    updatedAtSecs.toInt() * 1000,
    isUtc: true,
  );
  final gap = now.toUtc().difference(then);
  if (gap.inMinutes < 1) return 'Baru saja';
  if (gap.inMinutes < 60) return '${gap.inMinutes} mnt lalu';
  if (gap.inHours < 24) return '${gap.inHours} jam lalu';
  if (gap.inDays < 2) return 'Kemarin';
  if (gap.inDays < 7) return '${gap.inDays} hari lalu';
  if (gap.inDays < 14) return 'Minggu lalu';
  if (gap.inDays < 30) return '${gap.inDays ~/ 7} minggu lalu';
  return 'Lebih sebulan lalu';
}

String? remainingLabel(ProgressDto progress) {
  if (progress.length <= 0) return null;
  return switch (progress.kind) {
    MediaKindDto.anime => _minutesLeft(progress),
    MediaKindDto.manga =>
      'halaman ${progress.position.round()} dari ${progress.length.round()}',
    MediaKindDto.novel =>
      'paragraf ${progress.position.round()} dari ${progress.length.round()}',
  };
}

String _minutesLeft(ProgressDto progress) {
  final left = (progress.length - progress.position).clamp(0, progress.length);
  if (left < _secondsPerMinute) return 'sisa kurang dari 1 mnt';
  return 'sisa ${(left / _secondsPerMinute).ceil()} mnt';
}

int percentDone(ProgressDto progress) {
  if (progress.length <= 0) return 0;
  return (progress.position / progress.length * 100).clamp(0, 100).round();
}
