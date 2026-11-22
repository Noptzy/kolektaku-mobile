import 'package:flutter/widgets.dart';

import '../../src/rust/dto/media.dart';
import '../watch/episodes_sheet.dart';
import 'read_request.dart';
import 'reader_controller.dart';

String readerTitle(ReadRequest request, double chapter) =>
    '${request.title}  ·  ${episodeTag(MediaKindDto.manga, chapter)}';

void showReaderChapters(BuildContext context, ReaderController controller) {
  showEpisodesSheet(
    context,
    units: controller.units,
    current: controller.current,
    kind: MediaKindDto.manga,
    infos: const {},
    onPick: controller.goTo,
  );
}
