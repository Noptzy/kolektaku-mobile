import 'package:flutter/painting.dart';

import '../../src/rust/dto/settings.dart';

const readingSizeNames = {
  ReadingSizeDto.smallest: 'Sangat kecil',
  ReadingSizeDto.small: 'Kecil',
  ReadingSizeDto.medium: 'Sedang',
  ReadingSizeDto.large: 'Besar',
  ReadingSizeDto.largest: 'Sangat besar',
};

const readingSpacingNames = {
  ReadingSpacingDto.tight: 'Rapat',
  ReadingSpacingDto.normal: 'Biasa',
  ReadingSpacingDto.loose: 'Renggang',
};

const readingSample =
    'Angin malam membawa aroma hujan ke jendela. Ia menutup buku itu pelan-pelan, lalu menatap lampu yang berkedip.';

double fontSizeOf(ReadingSizeDto size) => switch (size) {
  ReadingSizeDto.smallest => 14,
  ReadingSizeDto.small => 16,
  ReadingSizeDto.medium => 18,
  ReadingSizeDto.large => 21,
  ReadingSizeDto.largest => 24,
};

double lineHeightOf(ReadingSpacingDto spacing) => switch (spacing) {
  ReadingSpacingDto.tight => 1.4,
  ReadingSpacingDto.normal => 1.7,
  ReadingSpacingDto.loose => 2.0,
};

TextStyle paragraphStyle(
  TextStyle base,
  ReadingSizeDto size,
  ReadingSpacingDto spacing,
) {
  return base.copyWith(
    fontSize: fontSizeOf(size),
    height: lineHeightOf(spacing),
  );
}
