import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/downloads/download_fab.dart';
import 'package:kolektaku/features/downloads/download_ring.dart';
import 'package:kolektaku/features/downloads/downloads_screen.dart';
import 'package:kolektaku/features/downloads/episode_picker.dart';
import 'package:kolektaku/src/rust/dto/downloads.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import '../../support/screen_harness.dart';
import '../../widgets/widget_harness.dart';
import 'download_support.dart';

void main() {
  testWidgets('the round button appears with a ring while downloading', (
    tester,
  ) async {
    final harness = ScreenHarness();
    harness.downloads.jobs = [job(1, DownloadPhaseDto.fetching, progress: 0.4)];
    await harness.pump(
      tester,
      const Align(alignment: Alignment.bottomRight, child: DownloadFab()),
      settle: false,
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('download-fab')), findsOneWidget);
    final ring = tester.widget<DownloadRing>(find.byType(DownloadRing));
    expect(ring.progress, closeTo(0.4, 0.001));
    await tester.tap(find.byKey(const Key('download-fab')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(harness.visits.last.path, Routes.downloads);
    harness.downloads.jobs = [];
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('nothing downloading leaves no button', (tester) async {
    final harness = ScreenHarness();
    harness.downloads.jobs = [job(1, DownloadPhaseDto.done)];
    await harness.pump(tester, const Center(child: DownloadFab()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('download-fab')), findsNothing);
  });

  testWidgets('the downloads page lists each job with the right actions', (
    tester,
  ) async {
    final harness = ScreenHarness();
    harness.downloads.jobs = [
      job(1, DownloadPhaseDto.fetching, progress: 0.5, bytes: 3 * 1024 * 1024),
      job(2, DownloadPhaseDto.failed, episode: 2),
      job(3, DownloadPhaseDto.done, episode: 3, filePath: 'content://media/3'),
    ];
    await harness.pump(tester, const DownloadsScreen(), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Mengunduh 50% · 3,0 MB'), findsOneWidget);
    expect(find.byKey(const Key('download-cancel-1')), findsOneWidget);
    expect(find.byKey(const Key('download-retry-2')), findsOneWidget);
    expect(find.byKey(const Key('download-open-3')), findsOneWidget);
    await tester.tap(find.byKey(const Key('download-cancel-1')));
    await tester.pump();
    expect(harness.downloads.cancelled, [1]);
    await tester.tap(find.byKey(const Key('download-open-3')));
    await tester.pump();
    expect(harness.device.opened, ['content://media/3']);
    harness.downloads.jobs = [];
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('an empty downloads page says how to start', (tester) async {
    final harness = ScreenHarness();
    await harness.pump(tester, const DownloadsScreen());
    expect(find.byKey(const Key('downloads-empty')), findsOneWidget);
  });

  testWidgets('the picker selects all open episodes and skips saved ones', (
    tester,
  ) async {
    List<UnitDto>? confirmed;
    await pumpAtSize(
      tester,
      EpisodePicker(
        units: [
          for (var i = 1; i <= 4; i++)
            UnitDto(id: 'u$i', number: i.toDouble(), label: 'Episode $i'),
        ],
        downloaded: {2.0},
        onConfirm: (units) => confirmed = units,
      ),
    );
    expect(find.text('Pilih episode dulu'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pick-all')));
    await tester.pump();
    expect(find.text('Unduh 3 episode'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pick-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pick-confirm')));
    expect(confirmed!.map((unit) => unit.number), [3, 4]);
  });
}
