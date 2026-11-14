import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/data/core_session.dart';
import 'package:kolektaku/src/rust/api/browse.dart' as browse;
import 'package:kolektaku/src/rust/api/detail.dart' as detail;
import 'package:kolektaku/src/rust/api/play.dart' as play;
import 'package:kolektaku/src/rust/api/sources.dart' as sources;
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

import 'support/pipeline_steps.dart';

const kimiNoNaWa = 21519;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await startCore();
  });

  test('the anime home has catalog sections and the sites latest', () async {
    final home = await browse.home(kind: MediaKindDto.anime);
    final ids = home.sections.map((section) => section.id).toList();
    expect(ids, containsAll(['trending', 'latest']));
    for (final section in home.sections) {
      expect(section.cards, isNotEmpty, reason: section.id);
    }
    expect(home.sections.last.cards.first.sources, isNotEmpty);
  });

  test('searching a misspelling still finds Kimi no Na wa', () async {
    final page = await search(MediaKindDto.anime, 'kimi no nawa');
    final film = cardTitled(page, 'Kimi no Na wa.');
    expect(film.reference.id, BigInt.from(kimiNoNaWa));
    expect(film.sources, contains('kuramanime'));
  });

  test('the detail resolves a source and lists the episode', () async {
    final view = await detail.mediaDetail(
      kind: MediaKindDto.anime,
      reference: catalogRef(kimiNoNaWa),
    );
    final catalog = view.catalog!;
    expect(catalog.detail.summary.titleRomaji, 'Kimi no Na wa.');
    expect(catalog.sources.first.source, 'kuramanime');
    expect(await unitCountOf(catalogRef(kimiNoNaWa)), 1);
  });

  test('an episode reaches a playable stream through the WebView', () async {
    final stream = await resolveFirstServer(catalogRef(kimiNoNaWa), 1);
    expect(stream.set.sources, isNotEmpty);
    expect(stream.set.sources.first.isDefault, isTrue);
    expect(stream.set.sources.first.url, startsWith('https://'));
    expect(stream.headers['Referer'], isNotNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('the resolved stream really plays for several seconds', () async {
    final position = await playedWithOneRetry(
      () => resolveFirstServer(catalogRef(kimiNoNaWa), 1),
      const Duration(seconds: 8),
    );
    expect(position, greaterThan(const Duration(seconds: 3)));
  }, timeout: const Timeout(Duration(minutes: 4)));

  test('manga opens a chapter whose images are really served', () async {
    final page = await search(MediaKindDto.manga, 'chainsaw man');
    final card = page.cards.firstWhere(
      (card) => card.title.toLowerCase().contains('chainsaw man'),
    );
    await openDetail(MediaKindDto.manga, card.reference);
    final view = await explained(
      () => play.openChapter(
        reference: card.reference,
        chapter: 1,
        exclude: const [],
      ),
    );
    expect(view.pages.length, greaterThanOrEqualTo(3));
    final status = await firstImageStatus(
      view.pages.first,
      'https://komiku.org/',
    );
    expect(status, 200);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a site that is switched off leaves the search results', () async {
    await sources.setSourceEnabled(id: 'kuramanime', enabled: false);
    try {
      final off = await search(MediaKindDto.anime, 'kimi no na wa');
      expect(
        cardTitled(off, 'Kimi no Na wa.').sources,
        isNot(contains('kuramanime')),
      );
    } finally {
      await sources.setSourceEnabled(id: 'kuramanime', enabled: true);
    }
    final on = await search(MediaKindDto.anime, 'kimi no na wa');
    expect(cardTitled(on, 'Kimi no Na wa.').sources, contains('kuramanime'));
  });
}
