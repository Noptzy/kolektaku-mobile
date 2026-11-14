import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../home/resume_card.dart';

MediaCardDto favoriteCard(FavoriteDto favorite) {
  return MediaCardDto(
    reference: favorite.reference,
    title: favorite.title,
    coverUrl: favorite.coverUrl,
    genres: const [],
    limited: false,
    sources: const [],
  );
}

String agoLabel(BigInt savedAtSecs, int nowSecs) {
  final seconds = nowSecs - savedAtSecs.toInt();
  if (seconds < 60) return 'Baru saja';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes menit lalu';
  final hours = minutes ~/ 60;
  if (hours < 24) return '$hours jam lalu';
  final days = hours ~/ 24;
  if (days == 1) return 'Kemarin';
  if (days < 7) return '$days hari lalu';
  final weeks = days ~/ 7;
  if (weeks < 5) return '$weeks minggu lalu';
  final months = days ~/ 30;
  if (months < 12) return '$months bulan lalu';
  return '${days ~/ 365} tahun lalu';
}

String historyLine(ProgressDto progress) {
  final unit = resumeMeta(progress.kind, progress.unitNumber);
  if (progress.completed) return '$unit · Selesai';
  if (progress.length <= 0) return unit;
  if (progress.kind == MediaKindDto.manga) {
    return '$unit · Hal. ${progress.position.round()} dari ${progress.length.round()}';
  }
  final percent = (progress.position / progress.length * 100)
      .clamp(0, 100)
      .round();
  return '$unit · $percent%';
}

double? historyFraction(ProgressDto progress) {
  if (progress.completed || progress.length <= 0) return null;
  return (progress.position / progress.length).clamp(0.0, 1.0);
}

String historyKey(ProgressDto progress) =>
    '${progress.reference.id}|${progress.unitNumber}';

String collectionTitle(MediaKindDto kind) =>
    kind == MediaKindDto.anime ? 'Anime' : 'Manga';

String emptyFavorites(MediaKindDto kind) =>
    'Belum ada ${collectionTitle(kind).toLowerCase()} favorit. Ketuk ikon hati di halaman detail.';

String emptyHistory(MediaKindDto kind) => kind == MediaKindDto.anime
    ? 'Belum ada yang ditonton.'
    : 'Belum ada yang dibaca.';
