import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/src/rust/api/library.dart' as shelf;
import 'package:kolektaku/src/rust/api/play.dart' as play;
import 'package:kolektaku/src/rust/api/sources.dart' as sources;
import 'package:kolektaku/src/rust/dto/library.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';
import 'package:kolektaku/src/rust/error.dart';

import 'core_library.dart';

void main() {
  late Directory folder;

  setUpAll(() async {
    if (hostLibraryMissing) return;
    folder = await startHostCore();
  });

  tearDownAll(() async {
    if (!hostLibraryMissing && folder.existsSync()) {
      await deleteBestEffort(folder);
    }
  });

  final skip = hostLibraryMissing ? missingReason : false;
  final reference = MediaRefDto(
    kind: MediaRefKind.catalog,
    id: BigInt.from(140960),
    source: '',
    item: '',
  );

  test('every registered site is reported and can be switched', () async {
    final all = await sources.sourcesStatus();
    final ids = all.map((status) => status.id).toSet();
    expect(ids, containsAll(['kuramanime', 'komiku', 'komikindo']));
    expect(all.every((status) => status.enabled), isTrue);
    await sources.setSourceEnabled(id: 'komiku', enabled: false);
    final after = await sources.sourcesStatus();
    expect(after.firstWhere((s) => s.id == 'komiku').enabled, isFalse);
    await sources.setSourceEnabled(id: 'komiku', enabled: true);
  }, skip: skip);

  test('a Kuramanime episode plans a web view pinned to its host', () async {
    final plan = await play.streamPlan(
      source: 'kuramanime',
      episodeId: '50/one-piece/episode/3',
      server: 'kuramadrive',
    );
    expect(plan.kind, StreamPlanKind.needsWebView);
    expect(Uri.parse(plan.url).host, plan.allowedHost);
    expect(plan.script, contains('"kuramadrive"'));
  }, skip: skip);

  test('a bad episode id comes back as a typed not-found error', () async {
    await expectLater(
      play.streamPlan(
        source: 'kuramanime',
        episodeId: '../admin',
        server: 'kuramadrive',
      ),
      throwsA(
        isA<BridgeError>().having(
          (error) => error.kind,
          'kind',
          BridgeErrorKind.notFound,
        ),
      ),
    );
  }, skip: skip);

  test(
    'a scraped payload is validated and ordered best quality first',
    () async {
      final set = await play.parseStreamPayload(
        source: 'kuramanime',
        payload:
            '{"poster":"https://img.test/p.jpg","sources":['
            '{"url":"https://cdn.test/a-480.mp4","type":"video/mp4","quality":"480"},'
            '{"url":"https://cdn.test/a-720.mp4","type":"video/mp4","quality":"720"}]}',
      );
      expect(set.sources.map((s) => s.quality), [720, 480]);
      expect(set.sources.first.isDefault, isTrue);
      expect(set.posterUrl, 'https://img.test/p.jpg');
    },
    skip: skip,
  );

  test('an unusable payload is a markup-changed error', () async {
    await expectLater(
      play.parseStreamPayload(source: 'kuramanime', payload: '{"sources":[]}'),
      throwsA(
        isA<BridgeError>().having(
          (error) => error.kind,
          'kind',
          BridgeErrorKind.markupChanged,
        ),
      ),
    );
  }, skip: skip);

  test('favorites and progress round-trip through the library', () async {
    final favorite = FavoriteDto(
      reference: reference,
      kind: MediaKindDto.anime,
      title: 'Spy x Family',
      addedAtSecs: BigInt.zero,
    );
    expect(await shelf.libraryToggleFavorite(favorite: favorite), isTrue);
    expect(
      await shelf.libraryIsFavorite(
        kind: MediaKindDto.anime,
        reference: reference,
      ),
      isTrue,
    );
    await shelf.librarySaveProgress(
      progress: ProgressDto(
        reference: reference,
        kind: MediaKindDto.anime,
        unitNumber: 2,
        title: 'Spy x Family',
        position: 100,
        length: 1440,
        updatedAtSecs: BigInt.from(5),
        completed: false,
      ),
    );
    final next = await shelf.libraryContinue(kind: MediaKindDto.anime);
    expect(next.single.unitNumber, 2);
    expect(await shelf.libraryToggleFavorite(favorite: favorite), isFalse);
  }, skip: skip);

  test('an invalid reference never reaches the library', () async {
    final invalid = MediaRefDto(
      kind: MediaRefKind.catalog,
      id: BigInt.zero,
      source: '',
      item: '',
    );
    await expectLater(
      shelf.libraryIsFavorite(kind: MediaKindDto.anime, reference: invalid),
      throwsA(isA<BridgeError>()),
    );
  }, skip: skip);
}
