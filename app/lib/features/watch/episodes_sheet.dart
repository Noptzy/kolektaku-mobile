import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import '../detail/episode_info_map.dart';
import '../detail/episode_row.dart';
import '../detail/episode_window.dart';

String episodeTag(MediaKindDto kind, double number) {
  final name = kind == MediaKindDto.anime ? 'Ep' : 'Ch';
  return '$name ${numberBadge(number)}';
}

const _sheetChrome = 130.0;

double sheetListHeight(double screenHeight) {
  final room = screenHeight - _sheetChrome;
  return room < 200 ? 200 : room;
}

double sheetOffsetFor(int index) {
  final wanted = (index - 1) * episodeRowHeight;
  return wanted < 0 ? 0 : wanted;
}

Future<void> showEpisodesSheet(
  BuildContext context, {
  required List<UnitDto> units,
  required double current,
  required MediaKindDto kind,
  required EpisodeInfos infos,
  required ValueChanged<UnitDto> onPick,
  String? art,
}) {
  final sorted = sortedUnits(units, descending: false);
  final at = indexOfNumber(sorted, current) ?? 0;
  final height = sheetListHeight(MediaQuery.sizeOf(context).height);
  return showShadSheet<void>(
    context: context,
    side: ShadSheetSide.right,
    builder: (sheetContext) => ShadSheet(
      title: Text(kind == MediaKindDto.anime ? 'Episode' : 'Chapter'),
      constraints: const BoxConstraints(maxWidth: 460),
      child: SizedBox(
        height: height,
        child: ListView.builder(
          key: const Key('episodes-list'),
          controller: ScrollController(initialScrollOffset: sheetOffsetFor(at)),
          itemExtent: episodeRowHeight,
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            final unit = sorted[index];
            return EpisodeRow(
              art: art,
              unit: unit,
              kind: kind,
              info: infos[unit.number],
              nowPlaying: unit.number == current,
              onTap: () {
                Navigator.of(sheetContext).pop();
                onPick(unit);
              },
            );
          },
        ),
      ),
    ),
  );
}
