import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/app.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/data/core_session.dart';
import 'package:kolektaku/features/watch/player/video_player_engine.dart';
import 'package:kolektaku/platform/picture_source.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

import 'package:kolektaku/features/scene_search/scene_candidate_row.dart';

import 'support/open_watch.dart';
import 'support/watch_driver.dart';

const officialSample = 'https://images.plurk.com/32B15UXxymfSMwKGTObY5e.jpg';

class SamplePictures implements PictureSource {
  SamplePictures(this.bytes);

  final Uint8List bytes;

  @override
  Future<Uint8List?> fromGallery() async => bytes;

  @override
  Future<Uint8List?> fromCamera() async => bytes;
}

Future<Uint8List> download(String url) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final builder = BytesBuilder();
    await for (final chunk in response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  } finally {
    client.close();
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await startCore();
  });

  testWidgets('the official sample picture starts playing at about 4:36', (
    tester,
  ) async {
    final sample = await download(officialSample);
    await tester.pumpWidget(
      kolektakuScope(
        overrides: [
          pictureSourceProvider.overrideWithValue(SamplePictures(sample)),
        ],
        child: const KolektakuApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    while (kolektakuRouter.canPop()) {
      kolektakuRouter.pop();
      await tester.pump(const Duration(milliseconds: 500));
    }
    kolektakuRouter.push(Routes.sceneSearch);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Pilih dari berkas'));
    final listed = await waitFor(
      tester,
      () => find.text('Mungkin ini adegannya').evaluate().isNotEmpty,
      timeout: const Duration(seconds: 90),
    );
    expect(listed, isTrue, reason: 'no candidates were listed');
    expect(find.text('Perkiraan posisi'), findsNothing);
    await tester.tap(find.byType(SceneCandidateRow).first);

    final started = await waitFor(
      tester,
      () => (shownPosition(tester) ?? Duration.zero) > Duration.zero,
      timeout: const Duration(seconds: 150),
    );
    expect(started, isTrue, reason: 'the scene never started playing');
    final first = shownPosition(tester)!;
    expect(
      first,
      greaterThanOrEqualTo(const Duration(minutes: 4, seconds: 36)),
    );
    expect(first, lessThanOrEqualTo(const Duration(minutes: 4, seconds: 45)));
    expect(find.text('Perkiraan posisi'), findsOneWidget);

    while (kolektakuRouter.canPop()) {
      kolektakuRouter.pop();
      await tester.pump(const Duration(milliseconds: 500));
    }
    await waitUntilReleased(tester: tester);
    expect(VideoPlayerEngine.liveControllers, 0);
  }, timeout: const Timeout(Duration(minutes: 6)));
}
