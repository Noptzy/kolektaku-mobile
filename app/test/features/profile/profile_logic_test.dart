import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/profile/profile_logic.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';

import '../detail/detail_support.dart';

AppearanceDto appearance(
  int id, {
  int? year,
  String? role,
  String? credit,
  List<String> characters = const [],
  String? format = 'TV',
}) {
  return AppearanceDto(
    media: summary(id: id, year: year, format: format, title: 'Judul $id'),
    role: role,
    characters: characters,
    credit: credit,
  );
}

void main() {
  group('groupByYear', () {
    test('the newest year comes first and the order inside a year stays', () {
      final groups = groupByYear([
        appearance(1, year: 2019),
        appearance(2, year: 2023),
        appearance(3, year: 2019),
        appearance(4, year: 2021),
      ]);
      expect(groups.map((group) => group.year), [2023, 2021, 2019]);
      expect(groups.last.items.map((item) => item.media.id), [
        BigInt.from(1),
        BigInt.from(3),
      ]);
    });

    test('titles without a year go last', () {
      final groups = groupByYear([
        appearance(1, year: null),
        appearance(2, year: 2000),
        appearance(3, year: null),
      ]);
      expect(groups.map((group) => group.year), [2000, null]);
      expect(groups.last.items.length, 2);
    });

    test('nothing in, nothing out', () {
      expect(groupByYear(const []), isEmpty);
    });
  });

  group('yearHeading', () {
    test('a year is itself and no year says so', () {
      expect(yearHeading(2016), '2016');
      expect(yearHeading(null), 'Tahun belum diketahui');
    });
  });

  group('appearanceMeta', () {
    test('a staff credit follows the format and the role', () {
      expect(
        appearanceMeta(appearance(1, credit: 'Story & Art')),
        'TV · Story & Art',
      );
      expect(
        appearanceMeta(appearance(1, role: 'MAIN', credit: 'Original Creator')),
        'TV · Utama · Original Creator',
      );
    });

    test('joins the format and the role in Indonesian', () {
      expect(appearanceMeta(appearance(1, role: 'MAIN')), 'TV · Utama');
      expect(
        appearanceMeta(appearance(1, role: 'SUPPORTING')),
        'TV · Pendukung',
      );
    });

    test('a voice actor title has just the format', () {
      expect(appearanceMeta(appearance(1)), 'TV');
    });

    test('nothing known means no line', () {
      expect(appearanceMeta(appearance(1, format: null)), isNull);
    });
  });

  group('appearanceVoiced', () {
    test('names every character voiced in the title', () {
      expect(
        appearanceVoiced(appearance(1, characters: ['Mayoi', 'Nadeko'])),
        'Sebagai Mayoi, Nadeko',
      );
    });

    test('a title without characters has no line', () {
      expect(appearanceVoiced(appearance(1)), isNull);
    });
  });

  group('profileTitle', () {
    test('names the kind of profile', () {
      expect(profileTitle(ProfileKindDto.character), 'Karakter');
      expect(profileTitle(ProfileKindDto.staff), 'Staf');
      expect(profileTitle(ProfileKindDto.studio), 'Studio');
    });
  });

  test('a manga title keeps its kind for opening', () {
    final item = AppearanceDto(
      media: summary(kind: MediaKindDto.manga),
      characters: const [],
    );
    expect(item.media.kind, MediaKindDto.manga);
  });

  group('appearanceTag', () {
    test('a staff credit wins over everything else', () {
      expect(
        appearanceTag(
          appearance(1, credit: 'Story & Art', role: 'MAIN', characters: ['A']),
        ),
        'Story & Art',
      );
    });

    test('a voice actor sees the characters voiced', () {
      expect(
        appearanceTag(appearance(1, characters: ['Mayoi', 'Nadeko'])),
        'Mayoi, Nadeko',
      );
    });

    test('a character sees the role it had', () {
      expect(appearanceTag(appearance(1, role: 'MAIN')), 'Utama');
      expect(appearanceTag(appearance(1, role: 'SUPPORTING')), 'Pendukung');
    });

    test('nothing to say means no tag', () {
      expect(appearanceTag(appearance(1)), isNull);
      expect(appearanceTag(appearance(1, credit: '')), isNull);
    });
  });

  group('appearanceCard', () {
    test('carries the title, picture and facts of the work', () {
      final card = appearanceCard(appearance(7, year: 2020, format: 'MOVIE'));
      expect(card.title, 'Judul 7');
      expect(card.year, 2020);
      expect(card.format, 'MOVIE');
      expect(card.reference.id, BigInt.from(7));
      expect(card.reference.kind, MediaRefKind.catalog);
      expect(card.limited, isFalse);
    });
  });
}
