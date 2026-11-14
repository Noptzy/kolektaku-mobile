import '../src/rust/dto/cards.dart';
import '../src/rust/dto/media.dart';

MediaRefDto catalogRef(BigInt id) =>
    MediaRefDto(kind: MediaRefKind.catalog, id: id, source: '', item: '');

MediaCardDto cardFromSummary(MediaSummaryDto summary) {
  return MediaCardDto(
    reference: catalogRef(summary.id),
    title: summary.titleRomaji,
    titleEnglish: summary.titleEnglish,
    coverUrl: summary.coverUrl,
    score: summary.score,
    year: summary.year,
    format: summary.format,
    status: summary.status,
    genres: summary.genres,
    unitCount: summary.unitCount,
    limited: false,
    sources: const [],
  );
}
