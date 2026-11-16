import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/collection/collection_logic.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../../features/detail/detail_support.dart';

ProgressDto progress({
  MediaKindDto kind = MediaKindDto.anime,
  double unit = 3,
  double position = 600,
  double length = 1200,
  bool completed = false,
}) {
  return ProgressDto(
    reference: ref(7),
    kind: kind,
    unitNumber: unit,
    title: 'Judul',
    position: position,
    length: length,
    updatedAtSecs: BigInt.zero,
    completed: completed,
  );
}

void main() {
  group('historyFraction', () {
    test('is the share watched while unfinished', () {
      expect(historyFraction(progress()), 0.5);
    });

    test('is nothing for finished or unknown lengths', () {
      expect(historyFraction(progress(completed: true)), isNull);
      expect(historyFraction(progress(length: 0)), isNull);
    });
  });

  test('a favorite becomes a card with its own title and cover', () {
    final card = favoriteCard(
      FavoriteDto(
        reference: ref(9),
        kind: MediaKindDto.anime,
        title: 'Favorit',
        coverUrl: 'https://img.test/c.jpg',
        addedAtSecs: BigInt.zero,
      ),
    );
    expect(card.title, 'Favorit');
    expect(card.coverUrl, 'https://img.test/c.jpg');
    expect(card.reference, ref(9));
  });

  test('the wording follows the kind', () {
    expect(collectionTitle(MediaKindDto.anime), 'Anime');
    expect(collectionTitle(MediaKindDto.manga), 'Komik');
    expect(collectionTitle(MediaKindDto.novel), 'Novel');
    expect(emptyHistory(MediaKindDto.anime), contains('ditonton'));
    expect(emptyHistory(MediaKindDto.manga), contains('dibaca'));
    expect(emptyFavorites(MediaKindDto.manga), contains('komik'));
  });
}
