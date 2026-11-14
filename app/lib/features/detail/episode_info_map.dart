import '../../src/rust/dto/episodes.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../home/resume_card.dart';

typedef EpisodeInfos = Map<double, EpisodeInfoDto>;

EpisodeInfos episodeInfosOf(DetailViewDto? view) {
  final episodes = view?.catalog?.detail.episodes ?? const <EpisodeInfoDto>[];
  return {for (final episode in episodes) episode.number: episode};
}

String? artOf(DetailViewDto? view) {
  final detail = view?.catalog?.detail;
  if (detail == null) return null;
  final banner = detail.bannerUrl;
  if (banner != null && banner.isNotEmpty) return banner;
  return detail.summary.coverUrl;
}

String rowTitle(UnitDto unit, EpisodeInfoDto? info, MediaKindDto kind) {
  final named = info?.title.trim() ?? '';
  if (named.isNotEmpty) return named;
  return resumeMeta(kind, unit.number);
}

String? rowSubtitle(UnitDto unit, EpisodeInfoDto? info, MediaKindDto kind) {
  final named = info?.title.trim() ?? '';
  if (named.isEmpty) return null;
  return resumeMeta(kind, unit.number);
}

String numberBadge(double number) => unitText(number);
