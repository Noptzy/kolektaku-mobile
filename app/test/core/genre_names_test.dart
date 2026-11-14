import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/genre_names.dart';

void main() {
  test('known genres are translated', () {
    expect(genreLabel('Action'), 'Aksi');
    expect(genreLabel('Award Winning'), 'Peraih Penghargaan');
    expect(genreLabel('Slice of Life'), 'Keseharian');
  });

  test('unknown genres keep their own name', () {
    expect(genreLabel('Something New'), 'Something New');
  });
}
