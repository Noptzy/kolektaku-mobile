import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/widgets/media_card.dart';
import 'package:kolektaku/features/profile/profile_request.dart';
import 'package:kolektaku/features/profile/profile_screen.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/links.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';
import 'package:kolektaku/src/rust/dto/profile_facts.dart';
import 'package:kolektaku/widgets/skeleton.dart';

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
  testWidgets('the name and picture show before the data arrives', (
    tester,
  ) async {
    final hold = Completer<ProfileDto>();
    final harness = ScreenHarness();
    harness.catalog.onProfile = (kind, id) => hold.future;
    await harness.pump(
      tester,
      ProfileScreen(request: request()),
      settle: false,
    );
    expect(find.text('Nezuko'), findsOneWidget);
    expect(find.text('Karakter'), findsOneWidget);
    expect(find.byType(Skeleton), findsWidgets);
    hold.complete(profile());
    await tester.pumpAndSettle();
    expect(find.text('Nezuko Kamado'), findsOneWidget);
    expect(find.byType(Skeleton), findsNothing);
  });
  testWidgets('asks the catalog for the kind and id of the request', (
    tester,
  ) async {
    final harness = await open(tester, result: profile());
    expect(harness.catalog.profileAsks, ['character|127518']);
  });
  testWidgets('a voice actor page is titled by the kind', (tester) async {
    await open(
      tester,
      result: profile(),
      asked: request(kind: ProfileKindDto.staff),
    );
    expect(find.text('Staf'), findsOneWidget);
  });
  testWidgets('shows the native name and the description as plain text', (
    tester,
  ) async {
    await open(tester, result: profile());
    expect(find.text('竈門禰豆子'), findsOneWidget);
    expect(find.text('Anak baik\ndan kuat & setia.'), findsOneWidget);
    expect(find.textContaining('<b>'), findsNothing);
  });
  testWidgets('titles are grouped under their year, newest first', (
    tester,
  ) async {
    await open(
      tester,
      result: profile(
        appearances: [
          appearance(1, year: 2019, role: 'MAIN'),
          appearance(2, year: 2023, role: 'SUPPORTING'),
          appearance(3, year: 2019),
        ],
      ),
    );
    final y2023 = tester.getTopLeft(find.text('2023')).dy;
    final y2019 = tester.getTopLeft(find.text('2019')).dy;
    expect(y2023, lessThan(y2019));
    expect(find.byType(MediaCard), findsNWidgets(3));
    expect(find.text('Utama'), findsOneWidget);
    expect(find.text('Pendukung'), findsOneWidget);
  });
  testWidgets('a voice actor sees the characters voiced in each title', (
    tester,
  ) async {
    await open(
      tester,
      result: profile(
        appearances: [
          appearance(1, year: 2012, characters: ['Mayoi', 'Nadeko']),
        ],
      ),
      asked: request(kind: ProfileKindDto.staff),
    );
    expect(find.text('Mayoi, Nadeko'), findsOneWidget);
  });
  testWidgets('tapping a title opens its detail with the right kind', (
    tester,
  ) async {
    final harness = await open(
      tester,
      result: profile(
        appearances: [
          AppearanceDto(
            media: summary(
              id: 77,
              kind: MediaKindDto.manga,
              year: 2016,
              title: 'Komik Judul',
            ),
            characters: const [],
          ),
        ],
      ),
    );
    await tester.tap(find.text('Komik Judul'));
    await tester.pumpAndSettle();
    final visit = harness.visits.single;
    expect(visit.path, Routes.detail);
    final detail = visit.extra! as DetailRequest;
    expect(detail.kind, MediaKindDto.manga);
    expect(detail.reference.id, BigInt.from(77));
    expect(detail.reference.kind, MediaRefKind.catalog);
  });
  testWidgets('no titles shows an empty state', (tester) async {
    await open(tester, result: profile());
    expect(find.text('Belum ada judul untuk ditampilkan'), findsOneWidget);
  });
  testWidgets('a missing description leaves no gap or label', (tester) async {
    await open(tester, result: profile(description: ''));
    expect(find.text('Selengkapnya'), findsNothing);
  });
  testWidgets('the description folds and unfolds', (tester) async {
    await open(
      tester,
      result: profile(
        description: List.filled(40, 'kalimat panjang').join(' '),
      ),
    );
    expect(find.text('Selengkapnya'), findsOneWidget);
    await tester.tap(find.text('Selengkapnya'));
    await tester.pumpAndSettle();
    expect(find.text('Lebih sedikit'), findsOneWidget);
  });
}
