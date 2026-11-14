import '../../core/labels.dart';
import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/profile.dart';
import '../../src/rust/dto/profile_summary.dart';

typedef YearGroup = ({int? year, List<AppearanceDto> items});

List<YearGroup> groupByYear(List<AppearanceDto> items) {
  final byYear = <int?, List<AppearanceDto>>{};
  for (final item in items) {
    byYear.putIfAbsent(item.media.year, () => []).add(item);
  }
  final years = byYear.keys.whereType<int>().toList()
    ..sort((a, b) => b.compareTo(a));
  return [
    for (final year in years) (year: year, items: byYear[year]!),
    if (byYear.containsKey(null)) (year: null, items: byYear[null]!),
  ];
}

String yearHeading(int? year) =>
    year == null ? 'Tahun belum diketahui' : '$year';

String? appearanceMeta(AppearanceDto item) {
  final parts = [
    formatLabel(item.media.format),
    if (item.role != null) roleLabel(item.role!),
    if (item.credit != null) item.credit!,
  ].whereType<String>().toList();
  return parts.isEmpty ? null : parts.join(' · ');
}

String? appearanceVoiced(AppearanceDto item) {
  if (item.characters.isEmpty) return null;
  return 'Sebagai ${item.characters.join(', ')}';
}

String? appearanceTag(AppearanceDto item) {
  final credit = item.credit;
  if (credit != null && credit.isNotEmpty) return credit;
  if (item.characters.isNotEmpty) return item.characters.join(', ');
  final role = item.role;
  return role == null ? null : roleLabel(role);
}

MediaCardDto appearanceCard(AppearanceDto item) {
  final media = item.media;
  return MediaCardDto(
    reference: MediaRefDto(
      kind: MediaRefKind.catalog,
      id: media.id,
      source: '',
      item: '',
    ),
    title: media.titleRomaji,
    titleEnglish: media.titleEnglish,
    coverUrl: media.coverUrl,
    score: media.score,
    year: media.year,
    format: media.format,
    status: media.status,
    genres: media.genres,
    unitCount: media.unitCount,
    limited: false,
    sources: const [],
  );
}

String profileTitle(ProfileKindDto kind) => switch (kind) {
  ProfileKindDto.character => 'Karakter',
  ProfileKindDto.staff => 'Staf',
  ProfileKindDto.studio => 'Studio',
};

const _occupations = {
  'Voice Actor': 'Pengisi suara',
  'Director': 'Sutradara',
  'Manga Artist': 'Mangaka',
  'Novelist': 'Novelis',
  'Writer': 'Penulis',
  'Illustrator': 'Ilustrator',
  'Singer': 'Penyanyi',
  'Composer': 'Komposer',
  'Animator': 'Animator',
  'Producer': 'Produser',
  'Character Designer': 'Desainer karakter',
  'Original Creator': 'Pencipta asli',
  'Sound Director': 'Sutradara suara',
};

String occupationLabel(String occupation) =>
    _occupations[occupation.trim()] ?? occupation.trim();

String? personSubtitle(ProfileSummaryDto person) {
  final text = person.subtitle;
  if (text == null || text.isEmpty) return null;
  return switch (person.kind) {
    ProfileKindDto.staff => text.split(', ').map(occupationLabel).join(', '),
    ProfileKindDto.character => 'Dari $text',
    ProfileKindDto.studio => 'Karya: $text',
  };
}
