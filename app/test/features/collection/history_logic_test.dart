import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/collection/history_logic.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import 'collection_support.dart';

void main() {
  test('the search ignores case and also matches the episode', () {
    final items = [progress(1, title: 'Hotaru'), progress(2, unit: 7)];
    expect(filterHistory(items, '  HOTARU ').single.title, 'Hotaru');
    expect(filterHistory(items, 'episode 7').single.title, 'Judul 2');
    expect(filterHistory(items, ''), items);
  });

  test('anime shows the watch time and other kinds a percentage', () {
    expect(historyTimeLabel(progress(1)), '10:00 / 20:00');
    expect(historyTimeLabel(progress(1, kind: MediaKindDto.manga)), '50%');
    expect(historyTimeLabel(progress(1, completed: true)), 'Selesai');
  });

  test('progress never leaves zero to one', () {
    expect(historyProgress(progress(1, position: 5000)), 1);
    expect(historyProgress(progress(1, completed: true)), 1);
    expect(historyProgress(progress(1, position: 300)), 0.25);
  });

  test('the same title on another episode has its own key', () {
    expect(
      historyKey(progress(1, unit: 1)),
      isNot(historyKey(progress(1, unit: 2))),
    );
  });
}
