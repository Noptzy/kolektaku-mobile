import 'package:kolektaku/src/rust/dto/credits.dart';
import 'package:kolektaku/src/rust/dto/episodes.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/links.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:kolektaku/src/rust/dto/studio.dart';

const filmId = 21519;

MediaRefDto ref(int id) => MediaRefDto(
  kind: MediaRefKind.catalog,
  id: BigInt.from(id),
  source: '',
  item: '',
);

MediaSummaryDto summary({
  int id = filmId,
  MediaKindDto kind = MediaKindDto.anime,
  String title = 'Kimi no Na wa.',
  String? english = 'Your Name.',
  String? format = 'MOVIE',
  String? status = 'FINISHED',
  int? year = 2016,
  int? units = 1,
  double? score = 8.6,
  List<String> genres = const ['Drama', 'Romance'],
}) {
  return MediaSummaryDto(
    id: BigInt.from(id),
    kind: kind,
    titleRomaji: title,
    titleEnglish: english,
    synonyms: const [],
    format: format,
    status: status,
    year: year,
    unitCount: units,
    score: score,
    genres: genres,
  );
}

MediaDetailDto detail({
  MediaSummaryDto? head,
  String description = 'Dua remaja bertukar tubuh.',
  TrailerDto? trailer,
  List<RelationDto> relations = const [],
  List<CharacterDto> characters = const [],
  List<MediaSummaryDto> recommendations = const [],
  NextAiringDto? nextAiring,
  List<EpisodeInfoDto> episodes = const [],
  String? banner,
  List<ExternalLinkDto> links = const [],
  List<StudioRefDto>? studios,
}) {
  return MediaDetailDto(
    summary: head ?? summary(),
    description: description,
    studios:
        studios ??
        [StudioRefDto(id: BigInt.from(1042), name: 'CoMix Wave Films')],
    season: 'SUMMER',
    startDate: const DateDto(year: 2016, month: 8, day: 26),
    endDate: const DateDto(year: 2016, month: 8, day: 26),
    durationMinutes: 107,
    characters: characters,
    staff: const [],
    trailer: trailer,
    relations: relations,
    recommendations: recommendations,
    nextAiring: nextAiring,
    source: 'ORIGINAL',
    episodes: episodes,
    bannerUrl: banner,
    links: links,
  );
}

SourceLinkDto link(
  String id, {
  String? name,
  double confidence = 0.92,
  bool manual = false,
  int? units = 1,
}) {
  return SourceLinkDto(
    source: id,
    sourceName: name ?? id,
    item: 'item-$id',
    confidence: confidence,
    unitCount: units,
    manual: manual,
    needsHint: false,
  );
}

DetailViewDto catalogView({
  MediaDetailDto? head,
  List<SourceLinkDto>? sources,
}) {
  return DetailViewDto(
    catalog: CatalogDetailDto(
      detail: head ?? detail(),
      sources: sources ?? [link('kura', name: 'Kuramanime')],
    ),
  );
}

DetailViewDto siteView() {
  return const DetailViewDto(
    site: SiteDetailDto(
      source: 'kura',
      item: 'x',
      title: 'Judul Situs',
      alternativeTitles: ['Alt'],
      typeText: 'TV',
      year: 2024,
      unitCount: 12,
      synopsis: '',
      genres: ['Action'],
      latestLabel: 'Ep 12',
    ),
  );
}

UnitsDto units(int count, {String source = 'kura'}) {
  return UnitsDto(
    source: source,
    item: 'item-$source',
    units: [
      for (var i = 1; i <= count; i++)
        UnitDto(id: 'u$i', number: i.toDouble(), label: 'Episode $i'),
    ],
  );
}

ProgressDto progress(
  double unit, {
  double position = 300,
  double length = 1200,
  bool completed = false,
  int id = filmId,
  MediaKindDto kind = MediaKindDto.anime,
}) {
  return ProgressDto(
    reference: ref(id),
    kind: kind,
    unitNumber: unit,
    title: 'Kimi no Na wa.',
    position: position,
    length: length,
    updatedAtSecs: BigInt.zero,
    completed: completed,
  );
}
