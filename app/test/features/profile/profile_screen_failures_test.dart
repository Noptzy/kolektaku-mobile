import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/profile/profile_request.dart';
import 'package:kolektaku/features/profile/profile_screen.dart';
import 'package:kolektaku/src/rust/dto/links.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';
import 'package:kolektaku/src/rust/dto/profile_facts.dart';
import 'package:kolektaku/src/rust/error.dart';

import '../../support/screen_harness.dart';
import '../detail/detail_support.dart';

ProfileRequest request({ProfileKindDto kind = ProfileKindDto.character}) {
  return ProfileRequest(
    kind: kind,
    id: BigInt.from(127518),
    name: 'Nezuko',
    imageUrl: 'https://img.test/nezuko.png',
  );
}

AppearanceDto appearance(
  int id, {
  int? year,
  String? role,
  String? credit,
  List<String> characters = const [],
}) {
  return AppearanceDto(
    media: summary(id: id, year: year, title: 'Judul $id', format: 'TV'),
    role: role,
    characters: characters,
    credit: credit,
  );
}

ProfileDto profile({
  List<AppearanceDto> appearances = const [],
  String description = 'Anak <b>baik</b><br>dan kuat &amp; setia.',
  String? nativeName = '竈門禰豆子',
  List<ProfileFactDto> facts = const [],
  List<ExternalLinkDto> links = const [],
}) {
  return ProfileDto(
    id: BigInt.from(127518),
    name: 'Nezuko Kamado',
    nativeName: nativeName,
    imageUrl: 'https://img.test/nezuko.png',
    description: description,
    facts: facts,
    links: links,
    appearances: appearances,
  );
}

Future<ScreenHarness> open(
  WidgetTester tester, {
  ProfileDto? result,
  Object? error,
  ProfileRequest? asked,
  bool settle = true,
}) async {
  final harness = ScreenHarness();
  harness.catalog.profileResult = result;
  harness.catalog.profileError = error;
  await harness.pump(
    tester,
    ProfileScreen(request: asked ?? request()),
    settle: settle,
  );
  return harness;
}

void main() {
  testWidgets('a network failure offers a retry that asks again', (
    tester,
  ) async {
    final harness = ScreenHarness();
    var attempts = 0;
    harness.catalog.onProfile = (kind, id) async {
      attempts++;
      if (attempts == 1) {
        throw const BridgeError(kind: BridgeErrorKind.network, detail: 'x');
      }
      return profile();
    };
    await harness.pump(tester, ProfileScreen(request: request()));
    expect(attempts, 1);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Nezuko Kamado'), findsOneWidget);
  });
  testWidgets('an unknown profile keeps the name and offers no retry', (
    tester,
  ) async {
    await open(
      tester,
      error: const BridgeError(kind: BridgeErrorKind.notFound, detail: 'x'),
    );
    expect(find.text('Nezuko'), findsOneWidget);
    expect(find.text('Coba lagi'), findsNothing);
  });
  testWidgets('an unexpected failure says so and can retry', (tester) async {
    final harness = ScreenHarness();
    var attempts = 0;
    harness.catalog.onProfile = (kind, id) async {
      attempts++;
      if (attempts == 1) throw StateError('boom');
      return profile();
    };
    await harness.pump(tester, ProfileScreen(request: request()));
    expect(find.text('Profil belum bisa dimuat.'), findsOneWidget);
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Nezuko Kamado'), findsOneWidget);
  });
}
