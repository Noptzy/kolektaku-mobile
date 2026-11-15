import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/settings_providers.dart';
import 'package:kolektaku/features/settings/settings_edit.dart';
import 'package:kolektaku/src/rust/dto/settings.dart';

void main() {
  test('reading starts at the middle size and spacing', () {
    expect(defaultSettings.readingSize, ReadingSizeDto.medium);
    expect(defaultSettings.readingSpacing, ReadingSpacingDto.normal);
  });

  test('the reading look survives edits to other settings', () {
    final changed = defaultSettings.copyWith(
      readingSize: ReadingSizeDto.largest,
      readingSpacing: ReadingSpacingDto.loose,
    );
    expect(
      changed.copyWith(accent: '#3B82F6').readingSize,
      ReadingSizeDto.largest,
    );
    expect(
      changed.withAnimeSource('x').readingSpacing,
      ReadingSpacingDto.loose,
    );
    expect(
      changed.withDefaultSubtitleLook().readingSize,
      ReadingSizeDto.largest,
    );
  });

  test('the five sizes and three spacings are all there', () {
    expect(ReadingSizeDto.values, hasLength(5));
    expect(ReadingSpacingDto.values, hasLength(3));
  });
}
