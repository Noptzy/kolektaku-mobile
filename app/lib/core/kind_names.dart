import '../src/rust/dto/media.dart';

String kindTitle(MediaKindDto kind) => switch (kind) {
  MediaKindDto.anime => 'Anime',
  MediaKindDto.manga => 'Komik',
  MediaKindDto.novel => 'Novel',
};

String kindNoun(MediaKindDto kind) => kindTitle(kind).toLowerCase();
