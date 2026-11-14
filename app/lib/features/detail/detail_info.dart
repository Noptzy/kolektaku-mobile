import '../../core/plain_text.dart';
import '../../core/labels.dart';
import '../../src/rust/dto/credits.dart';
import '../../src/rust/dto/links.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../../src/rust/dto/studio.dart';

class DetailInfo {
  const DetailInfo({
    required this.kind,
    required this.title,
    required this.meta,
    required this.synopsis,
    required this.genres,
    required this.limited,
    this.altTitle,
    this.coverUrl,
    this.bannerUrl,
    this.score,
    this.trailer,
    this.links = const [],
    this.studios = const [],
    this.catalogId,
    this.format,
    this.unitCount,
  });

  factory DetailInfo.fromView(DetailViewDto view, MediaKindDto kind) {
    final catalog = view.catalog;
    if (catalog != null) return DetailInfo._catalog(catalog, kind);
    return DetailInfo._site(view.site!, kind);
  }

  factory DetailInfo._catalog(CatalogDetailDto catalog, MediaKindDto kind) {
    final detail = catalog.detail;
    final summary = detail.summary;
    final english = summary.titleEnglish;
    final alt = english != null && english != summary.titleRomaji
        ? english
        : summary.titleNative;
    return DetailInfo(
      kind: kind,
      title: summary.titleRomaji,
      altTitle: alt,
      coverUrl: summary.coverUrl,
      bannerUrl: detail.bannerUrl,
      meta: _join([
        summary.year?.toString(),
        formatLabel(summary.format),
        statusLabel(summary.status, kind),
        unitCountLabel(summary.unitCount, kind),
      ]),
      score: summary.score,
      synopsis: plainText(detail.description),
      genres: summary.genres,
      limited: false,
      trailer: detail.trailer,
      links: detail.links,
      studios: detail.studios,
      catalogId: summary.id,
      format: summary.format,
      unitCount: summary.unitCount,
    );
  }

  factory DetailInfo._site(SiteDetailDto site, MediaKindDto kind) {
    return DetailInfo(
      kind: kind,
      title: site.title,
      altTitle: site.alternativeTitles.isEmpty
          ? null
          : site.alternativeTitles.first,
      coverUrl: site.coverUrl,
      meta: _join([
        site.year?.toString(),
        site.typeText,
        unitCountLabel(site.unitCount, kind),
      ]),
      synopsis: site.synopsis,
      genres: site.genres,
      limited: true,
      unitCount: site.unitCount,
    );
  }

  final MediaKindDto kind;
  final String title;
  final String? altTitle;
  final String? coverUrl;
  final String? bannerUrl;
  final String meta;
  final double? score;
  final String synopsis;
  final List<String> genres;
  final bool limited;
  final TrailerDto? trailer;
  final List<ExternalLinkDto> links;
  final List<StudioRefDto> studios;
  final BigInt? catalogId;
  final String? format;
  final int? unitCount;

  bool get isFilm => format?.toUpperCase() == 'MOVIE' || unitCount == 1;

  static String _join(List<String?> parts) =>
      parts.where((part) => part != null && part.isNotEmpty).join(' · ');
}
