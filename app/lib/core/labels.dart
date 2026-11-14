import '../src/rust/dto/media.dart';

String? formatLabel(String? format) {
  if (format == null) return null;
  return switch (format.toUpperCase()) {
    'TV' || 'TV_SHORT' => 'TV',
    'MOVIE' => 'Film',
    'OVA' => 'OVA',
    'ONA' => 'ONA',
    'SPECIAL' => 'Spesial',
    'MUSIC' => 'Musik',
    'MANGA' => 'Manga',
    'NOVEL' => 'Novel',
    'ONE_SHOT' => 'One-shot',
    _ => format,
  };
}

String? statusLabel(String? status, MediaKindDto kind) {
  if (status == null) return null;
  final anime = kind == MediaKindDto.anime;
  return switch (status.toUpperCase()) {
    'FINISHED' => 'Tamat',
    'RELEASING' => anime ? 'Sedang tayang' : 'Berlanjut',
    'NOT_YET_RELEASED' => anime ? 'Belum tayang' : 'Belum terbit',
    'CANCELLED' => 'Dibatalkan',
    'HIATUS' => 'Hiatus',
    _ => status,
  };
}

String unitCountLabel(int? count, MediaKindDto kind) {
  if (count == null) return '';
  return '$count ${kind == MediaKindDto.anime ? 'eps' : 'ch'}';
}

String relationLabel(String relation) => switch (relation.toUpperCase()) {
  'ADAPTATION' => 'Adaptasi',
  'PREQUEL' => 'Sebelumnya',
  'SEQUEL' => 'Lanjutan',
  'PARENT' => 'Cerita utama',
  'SIDE_STORY' => 'Cerita sampingan',
  'SPIN_OFF' => 'Spin-off',
  'ALTERNATIVE' => 'Versi lain',
  'SUMMARY' => 'Ringkasan',
  'CHARACTER' => 'Karakter sama',
  'SOURCE' => 'Sumber asli',
  'COMPILATION' => 'Kompilasi',
  'CONTAINS' => 'Memuat',
  _ => 'Terkait',
};

String roleLabel(String role) => switch (role.toUpperCase()) {
  'MAIN' => 'Utama',
  'SUPPORTING' => 'Pendukung',
  'BACKGROUND' => 'Latar',
  _ => role,
};
