import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/home/home_actions.dart';
import 'package:kolektaku/features/home/resume_rail.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

import '../features/collection/collection_support.dart';
import 'widget_harness.dart';

const _sizes = {'390x844': phoneLarge, '360x780': phoneSmall};
const _shot = Key('resume-shot');

ProgressDto _item(
  int id,
  MediaKindDto kind,
  String title,
  double position,
  double length,
  Duration ago,
) {
  final base = progress(id, kind: kind, unit: 4, title: title);
  return ProgressDto(
    reference: base.reference,
    kind: kind,
    unitNumber: 4,
    title: title,
    position: position,
    length: length,
    updatedAtSecs: BigInt.from(
      DateTime.now().subtract(ago).millisecondsSinceEpoch ~/ 1000,
    ),
    completed: false,
  );
}

void main() {
  _sizes.forEach((label, size) {
    testWidgets('resume rail at $label', (tester) async {
      final items = [
        _item(
          1,
          MediaKindDto.anime,
          'Hotaru no Yomeiri',
          750,
          1450,
          const Duration(hours: 2),
        ),
        _item(
          2,
          MediaKindDto.manga,
          'Berserk',
          7,
          24,
          const Duration(days: 1, hours: 3),
        ),
        _item(
          3,
          MediaKindDto.novel,
          'Tensei shitara Slime Datta Ken Gaiden',
          40,
          120,
          const Duration(days: 4),
        ),
      ];
      await pumpAtSize(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _shot,
            child: ColoredBox(
              color: const Color(0xFF0E0E12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResumeRail(
                    items: items,
                    actions: HomeActions(
                      onOpen: (kind, card) {},
                      onResume: (_) {},
                      onGenre: (kind, genre) {},
                      onAllGenres: (kind) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        size: size,
      );
      await expectLater(
        find.byKey(_shot),
        matchesGoldenFile('goldens/resume_$label.png'),
      );
    });
  });
}
