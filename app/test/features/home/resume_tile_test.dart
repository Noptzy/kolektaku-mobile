import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/home/resume_tile.dart';
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/screen_harness.dart';
import '../collection/collection_support.dart';

final _now = DateTime.utc(2026, 11, 22, 12);

ProgressDto _item({
  MediaKindDto kind = MediaKindDto.anime,
  String title = 'Hotaru no Yomeiri',
  double position = 750,
  double length = 1450,
  Duration ago = const Duration(hours: 2),
}) {
  final base = progress(1, kind: kind, unit: 4, title: title);
  return ProgressDto(
    reference: base.reference,
    kind: kind,
    unitNumber: 4,
    title: title,
    position: position,
    length: length,
    updatedAtSecs: BigInt.from(
      _now.subtract(ago).millisecondsSinceEpoch ~/ 1000,
    ),
    completed: false,
  );
}

Future<void> _show(
  WidgetTester tester,
  ProgressDto item, {
  VoidCallback? onTap,
  Size size = const Size(390, 844),
}) {
  return ScreenHarness().pump(
    tester,
    Align(
      alignment: Alignment.topLeft,
      child: ResumeTile(progress: item, onTap: onTap ?? () {}, now: _now),
    ),
    size: size,
  );
}

void main() {
  testWidgets('shows kind, time, title, detail and percent', (tester) async {
    await _show(tester, _item());
    expect(find.text('Anime'), findsOneWidget);
    expect(find.text('2 jam lalu'), findsOneWidget);
    expect(find.text('Hotaru no Yomeiri'), findsOneWidget);
    expect(find.text('Episode 4 · sisa 12 mnt'), findsOneWidget);
    expect(find.text('52%'), findsOneWidget);
  });

  testWidgets('a comic and a novel name their own kind and position', (
    tester,
  ) async {
    await _show(
      tester,
      _item(
        kind: MediaKindDto.manga,
        position: 7,
        length: 24,
        title: 'Berserk',
      ),
    );
    expect(find.text('Komik'), findsOneWidget);
    expect(find.text('Chapter 4 · halaman 7 dari 24'), findsOneWidget);

    await _show(
      tester,
      _item(
        kind: MediaKindDto.novel,
        position: 40,
        length: 120,
        title: 'Novel',
      ),
    );
    expect(find.text('Novel'), findsWidgets);
    expect(find.text('Chapter 4 · paragraf 40 dari 120'), findsOneWidget);
  });

  testWidgets('tapping anywhere on the tile continues', (tester) async {
    var taps = 0;
    await _show(tester, _item(), onTap: () => taps++);
    await tester.tap(find.text('Hotaru no Yomeiri'));
    await tester.tap(find.byIcon(LucideIcons.play));
    expect(taps, 2);
  });

  testWidgets('is announced as one button with the whole story', (
    tester,
  ) async {
    await _show(tester, _item());
    final label = tester.getSemantics(find.byType(ResumeTile)).label;
    expect(label, contains('Lanjutkan Hotaru no Yomeiri'));
    expect(label, contains('Episode 4'));
  });

  testWidgets('a very long title stays on one line inside the tile', (
    tester,
  ) async {
    const long =
        'Tensei shitara Slime Datta Ken Gaiden: Tempest no Kyoudai to Sekai '
        'no Hate de Hajimaru Mono Gatari';
    await _show(tester, _item(title: long), size: const Size(360, 780));
    final tile = tester.getRect(find.byType(ResumeTile));
    final text = tester.getRect(find.text(long));
    expect(text.right, lessThanOrEqualTo(tile.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stays 304 wide and tall enough for large text', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await _show(tester, _item());
    final size = tester.getSize(find.byType(ResumeTile));
    expect(size.width, resumeTileWidth);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no progress at all still reads cleanly', (tester) async {
    await _show(tester, _item(position: 0, length: 0));
    expect(find.text('Episode 4'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });
}
