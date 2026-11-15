import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/kind_names.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

void main() {
  test('every kind has a title and a lowercase noun', () {
    expect(kindTitle(MediaKindDto.anime), 'Anime');
    expect(kindTitle(MediaKindDto.manga), 'Komik');
    expect(kindTitle(MediaKindDto.novel), 'Novel');
    expect(kindNoun(MediaKindDto.novel), 'novel');
    for (final kind in MediaKindDto.values) {
      expect(kindNoun(kind), kindTitle(kind).toLowerCase());
    }
  });
}
