import '../../core/dates.dart';
import '../../core/labels.dart';
import '../../src/rust/dto/credits.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';

String sourceMaterialLabel(String? source) {
  if (source == null) return '';
  return switch (source.toUpperCase()) {
    'MANGA' => 'Komik',
    'LIGHT_NOVEL' => 'Novel ringan',
    'NOVEL' => 'Novel',
    'VISUAL_NOVEL' => 'Visual novel',
    'VIDEO_GAME' => 'Gim',
    'ORIGINAL' => 'Orisinal',
    'WEB_NOVEL' => 'Novel web',
    'ANIME' => 'Anime',
    'OTHER' => 'Lainnya',
    _ => source,
  };
}

String seasonLabel(String? season) {
  if (season == null) return '';
  return switch (season.toUpperCase()) {
    'WINTER' => 'Musim dingin',
    'SPRING' => 'Musim semi',
    'SUMMER' => 'Musim panas',
    'FALL' => 'Musim gugur',
    _ => season,
  };
}

List<(String, String)> infoRows(MediaDetailDto detail, MediaKindDto kind) {
  final summary = detail.summary;
  final airing = detail.nextAiring;
  final rows = <(String, String)>[
    ('Format', formatLabel(summary.format) ?? ''),
    ('Status', statusLabel(summary.status, kind) ?? ''),
    ('Studio', detail.studios.map((studio) => studio.name).join(', ')),
    ('Musim', seasonLabel(detail.season)),
    ('Mulai', formatDate(detail.startDate) ?? ''),
    ('Selesai', formatDate(detail.endDate) ?? ''),
    (
      'Durasi',
      detail.durationMinutes == null ? '' : '${detail.durationMinutes} menit',
    ),
    ('Sumber cerita', sourceMaterialLabel(detail.source)),
    ('Skor', summary.score == null ? '' : summary.score!.toStringAsFixed(1)),
    if (airing != null)
      (
        'Tayang berikutnya',
        'Episode ${airing.episode}, ${formatAiring(airing.airingAtSecs)}',
      ),
  ];
  return rows.where((row) => row.$2.isNotEmpty).toList();
}

List<(String, String)> siteInfoRows(SiteDetailDto site) {
  final rows = <(String, String)>[
    ('Tipe', site.typeText ?? ''),
    ('Tahun', site.year?.toString() ?? ''),
    ('Asal', site.origin ?? ''),
    ('Terbaru', site.latestLabel ?? ''),
  ];
  return rows.where((row) => row.$2.isNotEmpty).toList();
}

const studioLabel = 'Studio';
