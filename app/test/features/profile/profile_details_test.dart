import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/profile/profile_request.dart';
import 'package:kolektaku/features/profile/profile_screen.dart';
import 'package:kolektaku/platform/url_opener.dart';
import 'package:kolektaku/src/rust/dto/links.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';
import 'package:kolektaku/src/rust/dto/profile_facts.dart';

import '../../support/fake_url_opener.dart';
import '../../support/screen_harness.dart';

ProfileFactDto fact(FactKindDto kind, String value) =>
    ProfileFactDto(kind: kind, value: value);

ExternalLinkDto link(String site, String url, {String kind = 'SOCIAL'}) =>
    ExternalLinkDto(site: site, url: url, kind: kind);

ProfileDto staffProfile({
  List<ProfileFactDto> facts = const [],
  List<ExternalLinkDto> links = const [],
}) {
  return ProfileDto(
    id: BigInt.from(95061),
    name: 'Chiwa Saitou',
    description: '',
    facts: facts,
    links: links,
    appearances: const [],
  );
}

Future<(ScreenHarness, FakeUrlOpener)> open(
  WidgetTester tester,
  ProfileDto result, {
  ProfileKindDto kind = ProfileKindDto.staff,
}) async {
  final harness = ScreenHarness();
  final opener = FakeUrlOpener();
  harness.catalog.profileResult = result;
  await harness.pump(
    tester,
    ProfileScreen(
      request: ProfileRequest(kind: kind, id: BigInt.one, name: 'Chiwa Saitou'),
    ),
    extra: [urlOpenerProvider.overrideWithValue(opener)],
  );
  return (harness, opener);
}

void main() {
  testWidgets('facts are listed with Indonesian labels and values', (
    tester,
  ) async {
    await open(
      tester,
      staffProfile(
        facts: [
          fact(FactKindDto.occupations, 'Voice Actor, Singer'),
          fact(FactKindDto.birthday, '1980-06-12'),
          fact(FactKindDto.age, '46'),
          fact(FactKindDto.gender, 'Female'),
          fact(FactKindDto.homeTown, 'Tokyo'),
          fact(FactKindDto.yearsActive, '2001-'),
          fact(FactKindDto.favourites, '4021'),
        ],
      ),
    );
    for (final text in [
      'Profesi',
      'Pengisi suara, Penyanyi',
      'Lahir',
      '12 Juni 1980',
      'Usia',
      '46',
      'Jenis kelamin',
      'Perempuan',
      'Asal',
      'Tokyo',
      'Aktif',
      'Sejak 2001',
      'Favorit',
      '4.021',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.byKey(const Key('fact-birthday')), findsOneWidget);
  });

  testWidgets('social and catalog links are buttons that open the address', (
    tester,
  ) async {
    final (_, opener) = await open(
      tester,
      staffProfile(
        links: [
          link('Twitter', 'https://twitter.com/chiwa'),
          link('Instagram', 'https://www.instagram.com/chiwa'),
          link('AniList', 'https://anilist.co/staff/1', kind: 'INFO'),
        ],
      ),
    );
    expect(find.text('Twitter'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('AniList'), findsOneWidget);
    await tester.tap(find.byKey(const Key('link-https://twitter.com/chiwa')));
    await tester.pumpAndSettle();
    expect(opener.opened, ['https://twitter.com/chiwa']);
  });

  testWidgets('a link that is not https is never offered', (tester) async {
    await open(
      tester,
      staffProfile(
        links: [
          link('Berbahaya', 'http://evil.test/x'),
          link('Aneh', 'javascript:alert(1)'),
          link('Twitter', 'https://twitter.com/ok'),
        ],
      ),
    );
    expect(find.text('Berbahaya'), findsNothing);
    expect(find.text('Aneh'), findsNothing);
    expect(find.text('Twitter'), findsOneWidget);
  });

  testWidgets('a studio page shows its kind and popularity', (tester) async {
    await open(
      tester,
      ProfileDto(
        id: BigInt.from(858),
        name: 'Wit Studio',
        description: '',
        facts: [
          fact(FactKindDto.studioType, 'animation'),
          fact(FactKindDto.favourites, '1234'),
        ],
        links: [link('AniList', 'https://anilist.co/studio/858', kind: 'INFO')],
        appearances: const [],
      ),
      kind: ProfileKindDto.studio,
    );
    expect(find.text('Studio'), findsOneWidget);
    expect(find.text('Studio animasi'), findsOneWidget);
    expect(find.text('1.234'), findsOneWidget);
    expect(find.text('AniList'), findsOneWidget);
  });

  testWidgets('without facts or links the details area stays empty', (
    tester,
  ) async {
    await open(tester, staffProfile());
    expect(find.text('Profesi'), findsNothing);
    expect(find.byKey(const Key('fact-age')), findsNothing);
  });
}
