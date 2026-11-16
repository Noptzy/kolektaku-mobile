import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/notifications/app_update_notice.dart';
import 'package:kolektaku/features/notifications/notice_texts.dart';
import 'package:kolektaku/features/notifications/notification_prefs.dart';
import 'package:kolektaku/src/rust/dto/follow.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

UpdateEventDto event({
  MediaKindDto kind = MediaKindDto.anime,
  double number = 13,
  String title = 'Frieren',
  MediaRefKind refKind = MediaRefKind.catalog,
}) => UpdateEventDto(
  kind: kind,
  reference: MediaRefDto(
    kind: refKind,
    id: BigInt.from(154587),
    source: refKind == MediaRefKind.source ? 'a' : '',
    item: refKind == MediaRefKind.source ? 'x/y' : '',
  ),
  title: title,
  unitNumber: number,
  previous: number - 1,
);

void main() {
  group('texts', () {
    test('each kind says what is new in plain Indonesian', () {
      expect(noticeBody(event()), 'Episode 13 sudah tayang');
      expect(
        noticeBody(event(kind: MediaKindDto.manga)),
        'Chapter 13 sudah terbit',
      );
      expect(
        noticeBody(event(kind: MediaKindDto.novel, number: 7.5)),
        'Chapter 7.5 sudah terbit',
      );
    });

    test('a summary names a few titles and says there are more', () {
      final many = [for (var i = 0; i < 6; i++) event(title: 'Judul $i')];
      expect(summaryTitle(6), '6 judul favoritmu ada yang baru');
      expect(
        summaryBody(many),
        'Judul 0, Judul 1, Judul 2, Judul 3, dan lainnya',
      );
      expect(summaryBody(many.take(2).toList()), 'Judul 0, Judul 1');
    });
  });

  group('tapping a notice', () {
    test('the payload leads back to the same title page', () {
      for (final original in [event(), event(refKind: MediaRefKind.source)]) {
        final request = requestFromPayload(payloadOf(original));
        expect(request, isNotNull);
        expect(request!.kind, original.kind);
        expect(request.reference, original.reference);
      }
    });

    test('a damaged payload opens nothing', () {
      for (final bad in [
        null,
        '',
        'a|b',
        'x|catalog|1||',
        'anime|nope|1||',
        'anime|catalog|abc||',
      ]) {
        expect(requestFromPayload(bad), isNull, reason: '$bad');
      }
    });
  });

  group('preferences', () {
    test('the interval falls back to two hours for anything odd', () {
      expect(hoursFrom('6'), 6);
      expect(hoursFrom('5'), defaultHours);
      expect(hoursFrom(null), defaultHours);
      expect(hoursFrom('abc'), defaultHours);
    });

    test('only an explicit one means enabled', () {
      expect(enabledFrom('1'), isTrue);
      expect(enabledFrom('0'), isFalse);
      expect(enabledFrom(null), isFalse);
    });
  });

  group('new version texts', () {
    test('an important update says so', () {
      expect(appUpdateTitle('0.4.0'), 'Kolektaku 0.4.0 tersedia');
      expect(appUpdateBody(required_: true), contains('penting'));
      expect(appUpdateBody(required_: false), isNot(contains('penting')));
    });
  });
}
