import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/features/detail/detail_screen.dart';
import 'package:kolektaku/features/profile/profile_request.dart';
import 'package:kolektaku/platform/url_opener.dart';
import 'package:kolektaku/src/rust/dto/credits.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/profile.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';

import '../../support/fake_url_opener.dart';
import '../../support/screen_harness.dart';
import 'detail_support.dart';

final request = DetailRequest(kind: MediaKindDto.anime, reference: ref(filmId));

class Opened {
  Opened(this.harness, this.opener);

  final ScreenHarness harness;
  final FakeUrlOpener opener;
}

Future<Opened> open(
  WidgetTester tester, {
  String? notice,
  DetailViewDto? view,
  int unitCount = 12,
  void Function(ScreenHarness harness)? prepare,
  List<Override> extra = const [],
}) async {
  final harness = ScreenHarness();
  final opener = FakeUrlOpener();
  harness.catalog.detailResult = view ?? catalogView();
  harness.catalog.unitsResult = units(unitCount);
  prepare?.call(harness);
  await harness.pump(
    tester,
    DetailScreen(
      request: DetailRequest(
        kind: MediaKindDto.anime,
        reference: ref(filmId),
        notice: notice,
      ),
    ),
    extra: [urlOpenerProvider.overrideWithValue(opener), ...extra],
  );
  return Opened(harness, opener);
}

Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('tabs', () {
    testWidgets('characters list the cast with the voice actor', (
      tester,
    ) async {
      await open(
        tester,
        view: catalogView(
          head: detail(
            characters: [
              CharacterDto(
                id: BigInt.one,
                name: 'Mitsuha',
                role: 'MAIN',
                voiceActors: [
                  VoiceActorDto(
                    id: BigInt.two,
                    name: 'Mone',
                    language: 'Japanese',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Karakter'));
      await tester.pumpAndSettle();
      expect(find.text('Mitsuha'), findsOneWidget);
      expect(find.text('Utama'), findsOneWidget);
      expect(find.text('Mone'), findsOneWidget);
      expect(find.text('Jepang'), findsOneWidget);
    });
    testWidgets('tapping the character opens its profile', (tester) async {
      final opened = await open(
        tester,
        view: catalogView(
          head: detail(
            characters: [
              CharacterDto(
                id: BigInt.from(11),
                name: 'Mitsuha',
                role: 'MAIN',
                imageUrl: 'https://img.test/m.jpg',
                voiceActors: [
                  VoiceActorDto(
                    id: BigInt.from(22),
                    name: 'Mone',
                    language: 'Japanese',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Karakter'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('character-${BigInt.from(11)}')));
      await tester.pumpAndSettle();
      final visit = opened.harness.visits.last;
      expect(visit.path, Routes.profile);
      final request = visit.extra! as ProfileRequest;
      expect(request.kind, ProfileKindDto.character);
      expect(request.id, BigInt.from(11));
      expect(request.name, 'Mitsuha');
      expect(request.imageUrl, 'https://img.test/m.jpg');
    });
    testWidgets('the voice actor side opens the staff profile', (tester) async {
      final opened = await open(
        tester,
        view: catalogView(
          head: detail(
            characters: [
              CharacterDto(
                id: BigInt.from(11),
                name: 'Mitsuha',
                role: 'MAIN',
                voiceActors: [
                  VoiceActorDto(
                    id: BigInt.from(22),
                    name: 'Mone',
                    imageUrl: 'https://img.test/v.jpg',
                    language: 'Japanese',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Karakter'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('voice-${BigInt.from(22)}')));
      await tester.pumpAndSettle();
      final request = opened.harness.visits.last.extra! as ProfileRequest;
      expect(request.kind, ProfileKindDto.staff);
      expect(request.id, BigInt.from(22));
      expect(request.imageUrl, 'https://img.test/v.jpg');
    });
  });
}
