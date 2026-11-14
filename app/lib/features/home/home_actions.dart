import 'package:flutter/foundation.dart';

import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';

class HomeActions {
  const HomeActions({
    required this.onOpen,
    required this.onResume,
    required this.onGenre,
    required this.onAllGenres,
  });

  final void Function(MediaKindDto kind, MediaCardDto card) onOpen;
  final ValueChanged<ProgressDto> onResume;
  final void Function(MediaKindDto kind, GenreDto genre) onGenre;
  final ValueChanged<MediaKindDto> onAllGenres;
}
