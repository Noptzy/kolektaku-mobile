import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/profile/profile_facts_logic.dart';
import 'package:kolektaku/features/profile/profile_logic.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';
import 'package:kolektaku/src/rust/dto/profile_facts.dart';
import 'package:kolektaku/src/rust/dto/profile_summary.dart';

ProfileFactDto fact(FactKindDto kind, String value) =>
    ProfileFactDto(kind: kind, value: value);

void main() {
  group('dateText', () {
    test('a full date is written out in Indonesian', () {
      expect(dateText('1980-06-12'), '12 Juni 1980');
      expect(dateText('1999-01-05'), '5 Januari 1999');
      expect(dateText('2001-12-31'), '31 Desember 2001');
    });

    test('a date without a year keeps the day and the month', () {
      expect(dateText('--12-28'), '28 Desember');
      expect(dateText('--03-01'), '1 Maret');
    });

    test('a month and a year, or only a year, are handled', () {
      expect(dateText('1990-03'), 'Maret 1990');
      expect(dateText('1990'), '1990');
    });

    test('anything unexpected is shown as it came', () {
      expect(dateText('besok'), 'besok');
      expect(dateText('1990-13-01'), '1990-13-01');
      expect(dateText('--00-01'), '--00-01');
    });
  });

  group('yearsText', () {
    test('one open year reads as since, two years as a range', () {
      expect(yearsText('2001-'), 'Sejak 2001');
      expect(yearsText('2001-2010'), '2001 – 2010');
    });

    test('broken text is left alone', () {
      expect(yearsText('lama'), 'lama');
      expect(yearsText('-2010'), '-2010');
    });
  });

  test('big counts get thousands separators and text is untouched', () {
    expect(groupThousands('4021'), '4.021');
    expect(groupThousands('1234567'), '1.234.567');
    expect(groupThousands('12'), '12');
    expect(groupThousands('banyak'), 'banyak');
  });

  group('factValue', () {
    test('gender, language and studio kind are translated', () {
      expect(factValue(fact(FactKindDto.gender, 'Female')), 'Perempuan');
      expect(factValue(fact(FactKindDto.gender, 'Male')), 'Laki-laki');
      expect(factValue(fact(FactKindDto.gender, 'Non-binary')), 'Non-biner');
      expect(factValue(fact(FactKindDto.gender, 'Robot')), 'Robot');
      expect(factValue(fact(FactKindDto.language, 'Japanese')), 'Jepang');
      expect(factValue(fact(FactKindDto.language, 'Tagalog')), 'Tagalog');
      expect(
        factValue(fact(FactKindDto.studioType, 'animation')),
        'Studio animasi',
      );
      expect(
        factValue(fact(FactKindDto.studioType, 'producer')),
        'Produser atau penerbit',
      );
    });

    test('occupations, dates and years go through their own formats', () {
      expect(
        factValue(fact(FactKindDto.occupations, 'Voice Actor, Singer')),
        'Pengisi suara, Penyanyi',
      );
      expect(
        factValue(fact(FactKindDto.birthday, '1980-06-12')),
        '12 Juni 1980',
      );
      expect(factValue(fact(FactKindDto.died, '2020')), '2020');
      expect(factValue(fact(FactKindDto.yearsActive, '2001-')), 'Sejak 2001');
      expect(factValue(fact(FactKindDto.favourites, '4021')), '4.021');
    });

    test('plain facts are shown as they are', () {
      expect(factValue(fact(FactKindDto.age, '14-15')), '14-15');
      expect(factValue(fact(FactKindDto.bloodType, 'AB')), 'AB');
      expect(factValue(fact(FactKindDto.homeTown, 'Tokyo')), 'Tokyo');
      expect(factValue(fact(FactKindDto.nicknames, 'Nezu-chan')), 'Nezu-chan');
    });
  });

  test('every kind of fact has an Indonesian label', () {
    for (final kind in FactKindDto.values) {
      expect(factLabel(kind), isNotEmpty, reason: kind.name);
    }
    expect(factLabel(FactKindDto.birthday), 'Lahir');
    expect(factLabel(FactKindDto.bloodType), 'Golongan darah');
  });

  group('profile titles and people subtitles', () {
    ProfileSummaryDto person(ProfileKindDto kind, String? subtitle) =>
        ProfileSummaryDto(
          kind: kind,
          id: BigInt.one,
          name: 'N',
          subtitle: subtitle,
        );

    test('each kind has its own page title', () {
      expect(profileTitle(ProfileKindDto.character), 'Karakter');
      expect(profileTitle(ProfileKindDto.staff), 'Staf');
      expect(profileTitle(ProfileKindDto.studio), 'Studio');
    });

    test('staff subtitles translate each occupation', () {
      expect(
        personSubtitle(
          person(ProfileKindDto.staff, 'Voice Actor, Manga Artist'),
        ),
        'Pengisi suara, Mangaka',
      );
      expect(personSubtitle(person(ProfileKindDto.staff, 'Skater')), 'Skater');
    });

    test('characters and studios name their best known work', () {
      expect(
        personSubtitle(person(ProfileKindDto.character, 'Demon Slayer')),
        'Dari Demon Slayer',
      );
      expect(
        personSubtitle(person(ProfileKindDto.studio, 'Attack on Titan')),
        'Karya: Attack on Titan',
      );
    });

    test('a missing or empty subtitle stays missing', () {
      expect(personSubtitle(person(ProfileKindDto.studio, null)), isNull);
      expect(personSubtitle(person(ProfileKindDto.staff, '')), isNull);
    });
  });
}
