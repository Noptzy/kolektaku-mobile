import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/sources.dart';
import 'home_sections.dart';

String? specificCover(String name, Map<String, String> covers, HomeDto? home) {
  final own = covers[name];
  if (own != null && own.isNotEmpty) return own;
  return home == null ? null : genreImage(name, home);
}

String? genreCover(String name, Map<String, String> covers, HomeDto? home) =>
    specificCover(name, covers, home);

List<GenreDto> featuredGenres(
  List<GenreDto> genres,
  Map<String, String> covers,
  HomeDto? home,
) {
  final withImage = <GenreDto>[];
  final without = <GenreDto>[];
  for (final genre in genres) {
    final target = specificCover(genre.name, covers, home) == null
        ? without
        : withImage;
    target.add(genre);
  }
  return [...withImage, ...without].take(genreTileCount).toList();
}
