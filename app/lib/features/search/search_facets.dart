enum SearchAiring {
  all('Semua', null),
  releasing('Sedang tayang', 'RELEASING'),
  finished('Sudah tamat', 'FINISHED'),
  upcoming('Akan datang', 'NOT_YET_RELEASED'),
  hiatus('Hiatus', 'HIATUS');

  const SearchAiring(this.label, this.apiName);

  final String label;
  final String? apiName;
}

enum SearchOrigin {
  all('Semua', null),
  manga('Manga', 'MANGA'),
  lightNovel('Novel ringan', 'LIGHT_NOVEL'),
  visualNovel('Novel visual', 'VISUAL_NOVEL'),
  videoGame('Game', 'VIDEO_GAME'),
  original('Cerita asli', 'ORIGINAL'),
  novel('Novel', 'NOVEL');

  const SearchOrigin(this.label, this.apiName);

  final String label;
  final String? apiName;
}

const searchGenres = [
  'Action',
  'Adventure',
  'Comedy',
  'Drama',
  'Fantasy',
  'Horror',
  'Mahou Shoujo',
  'Mecha',
  'Music',
  'Mystery',
  'Psychological',
  'Romance',
  'Sci-Fi',
  'Slice of Life',
  'Sports',
  'Supernatural',
  'Thriller',
];

const popularStudios = [
  'Studio Ghibli',
  'MAPPA',
  'ufotable',
  'Kyoto Animation',
  'Bones',
  'Madhouse',
  'Wit Studio',
  'A-1 Pictures',
  'CloverWorks',
  'Trigger',
  'Sunrise',
  'Toei Animation',
  'Production I.G',
  'Shaft',
  'Pierrot',
];
