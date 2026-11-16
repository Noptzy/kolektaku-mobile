import '../../core/kind_names.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';

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

double? historyFraction(ProgressDto progress) {
  if (progress.completed || progress.length <= 0) return null;
  return (progress.position / progress.length).clamp(0.0, 1.0);
}

String collectionTitle(MediaKindDto kind) => kindTitle(kind);

String emptyFavorites(MediaKindDto kind) =>
    'Belum ada ${collectionTitle(kind).toLowerCase()} favorit. Ketuk ikon hati di halaman detail.';

String emptyHistory(MediaKindDto kind) => kind == MediaKindDto.anime
    ? 'Belum ada yang ditonton.'
    : 'Belum ada yang dibaca.';
