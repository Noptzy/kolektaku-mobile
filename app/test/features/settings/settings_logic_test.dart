import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/settings/settings_logic.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

SourceStatusDto status(
  String id, {
  MediaKindDto kind = MediaKindDto.anime,
  bool enabled = true,
  bool skipped = false,
  String summary = '',
}) {
  return SourceStatusDto(
    id: id,
    name: 'Nama Situs $id',
    kind: kind,
    enabled: enabled,
    skipped: skipped,
    summary: summary,
  );
}

void main() {
  group('numberedSources', () {
    test('numbers each kind from one in the order given', () {
      final entries = numberedSources([
        status('a'),
        status('m', kind: MediaKindDto.manga),
        status('b'),
      ], MediaKindDto.anime);
      expect(entries.map((entry) => entry.status.id), ['a', 'b']);
      expect(entries.map((entry) => entry.number), [1, 2]);
    });

    test('a kind without sources has none', () {
      expect(numberedSources([status('a')], MediaKindDto.manga), isEmpty);
      expect(numberedSources(const [], MediaKindDto.anime), isEmpty);
    });
  });

  group('sourceLabel', () {
    test('never contains the name of a site', () {
      final label = sourceLabel(MediaKindDto.anime, 2);
      expect(label, 'Sumber anime 2');
      expect(label, isNot(contains('Nama Situs')));
      expect(sourceLabel(MediaKindDto.manga, 1), 'Sumber manga 1');
    });
  });

  group('sourceHint', () {
    test('tells off, skipped and active apart', () {
      expect(sourceHint(status('a', enabled: false)), 'Dimatikan');
      expect(sourceHint(status('a', skipped: true)), contains('dilewati'));
      expect(sourceHint(status('a')), 'Aktif');
    });

    test('switched off wins over skipped', () {
      expect(
        sourceHint(status('a', enabled: false, skipped: true)),
        'Dimatikan',
      );
    });
  });

  group('allOff', () {
    List<SourceEntry> entries(List<bool> flags) => numberedSources([
      for (var i = 0; i < flags.length; i++) status('s$i', enabled: flags[i]),
    ], MediaKindDto.anime);

    test('is true only when there are sources and every one is off', () {
      expect(allOff(entries([false, false])), isTrue);
      expect(allOff(entries([false, true])), isFalse);
      expect(allOff(entries(const [])), isFalse);
    });
  });

  test('the version line handles a missing version', () {
    expect(versionLabel('2.0.0'), 'Versi 2.0.0');
    expect(versionLabel(null), 'Versi tidak diketahui');
    expect(versionLabel(''), 'Versi tidak diketahui');
  });

  test('the credits name the data providers', () {
    final text = aboutLines.join(' ');
    expect(text, contains('AniList'));
    expect(text, contains('MyAnimeList'));
    expect(text, contains('trace.moe'));
  });
}
