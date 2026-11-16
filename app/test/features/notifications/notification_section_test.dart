import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/notifications/notification_prefs.dart';
import 'package:kolektaku/platform/background_checks.dart';
import 'package:kolektaku/features/settings/notification_section.dart';
import 'package:kolektaku/src/rust/dto/follow.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/fake_notifier.dart';
import '../../support/screen_harness.dart';

late MemoryPrefsStore prefs;

class FakeScheduler implements ChecksScheduler {
  final List<int> scheduled = [];
  int cancels = 0;

  @override
  Future<void> schedule(int hours) async => scheduled.add(hours);

  @override
  Future<void> cancel() async => cancels++;
}

late FakeScheduler scheduler;

Future<List<UpdateEventDto>> Function() noNews = () async => const [];

Future<FakeNotifier> open(
  WidgetTester tester, {
  bool permitted = true,
  bool grants = true,
  Future<List<UpdateEventDto>> Function()? check,
}) async {
  prefs = MemoryPrefsStore();
  NotificationPrefs.store = prefs;
  scheduler = FakeScheduler();
  checksScheduler = scheduler;
  addTearDown(() {
    NotificationPrefs.store = const CorePrefsStore();
    checksScheduler = const WorkmanagerScheduler();
  });
  final notifier = FakeNotifier(permitted: permitted, grants: grants);
  await ScreenHarness().pump(
    tester,
    SingleChildScrollView(
      child: NotificationSection(notifier: notifier, check: check ?? noNews),
    ),
    size: const Size(390, 1000),
  );
  return notifier;
}

void main() {
  testWidgets('the page starts off and explains where the permission stands', (
    tester,
  ) async {
    await open(tester, permitted: false);
    expect(
      find.textContaining('Izin notifikasi belum diberikan'),
      findsOneWidget,
    );
    expect(find.byType(NotificationSection), findsOneWidget);
  });

  testWidgets('turning it on asks for the permission once and remembers it', (
    tester,
  ) async {
    final notifier = await open(tester, permitted: false);
    await tester.tap(find.text('Kabari episode dan chapter baru'));
    await tester.pumpAndSettle();
    expect(notifier.permissionAsks, 1);
    expect(prefs.values[enabledKey], '1');
    expect(scheduler.scheduled, [2]);
  });

  testWidgets('a refused permission leaves it off', (tester) async {
    final notifier = await open(tester, permitted: false, grants: false);
    await tester.tap(find.text('Kabari episode dan chapter baru'));
    await tester.pumpAndSettle();
    expect(notifier.permissionAsks, 1);
    expect(prefs.values[enabledKey], '0');
    expect(scheduler.scheduled, isEmpty);
  });

  testWidgets('the test button shows a notification when allowed', (
    tester,
  ) async {
    final notifier = await open(tester);
    await tester.tap(find.byKey(const Key('notify-test')));
    await tester.pump();
    expect(notifier.tests, 1);
    expect(notifier.permissionAsks, 0);
  });

  testWidgets('the test button asks for the permission first when missing', (
    tester,
  ) async {
    final notifier = await open(tester, permitted: false);
    await tester.tap(find.byKey(const Key('notify-test')));
    await tester.pumpAndSettle();
    expect(notifier.permissionAsks, 1);
    expect(notifier.tests, 1);
  });

  testWidgets('a refused permission says so and shows nothing', (tester) async {
    final notifier = await open(tester, permitted: false, grants: false);
    await tester.tap(find.byKey(const Key('notify-test')));
    await tester.pumpAndSettle();
    expect(notifier.tests, 0);
    expect(find.textContaining('Izin notifikasi ditolak'), findsOneWidget);
  });

  testWidgets('checking now sends what is new as notifications', (
    tester,
  ) async {
    final event = UpdateEventDto(
      reference: MediaRefDto(
        kind: MediaRefKind.catalog,
        id: BigInt.one,
        source: '',
        item: '',
      ),
      kind: MediaKindDto.anime,
      title: 'Judul',
      unitNumber: 5,
      previous: 4,
    );
    final notifier = await open(tester, check: () async => [event]);
    await tester.tap(find.byKey(const Key('notify-check')));
    await tester.pumpAndSettle();
    expect(notifier.shown.single, [event]);
    expect(find.textContaining('1 kabar baru'), findsOneWidget);
  });

  testWidgets('checking now without news says so and shows nothing', (
    tester,
  ) async {
    final notifier = await open(tester);
    await tester.tap(find.byKey(const Key('notify-check')));
    await tester.pumpAndSettle();
    expect(notifier.shown, isEmpty);
    expect(
      find.textContaining('Belum ada episode atau chapter baru'),
      findsOneWidget,
    );
  });

  testWidgets('a failing check says it could not look and does not crash', (
    tester,
  ) async {
    final notifier = await open(
      tester,
      check: () async => throw StateError('offline'),
    );
    await tester.tap(find.byKey(const Key('notify-check')));
    await tester.pumpAndSettle();
    expect(notifier.shown, isEmpty);
    expect(find.textContaining('Belum bisa memeriksa'), findsOneWidget);
    expect(
      tester.widget<ShadButton>(find.byKey(const Key('notify-check'))).enabled,
      isTrue,
    );
  });

  testWidgets(
    'a new interval replaces the schedule and turning off cancels it',
    (tester) async {
      await open(tester, permitted: false);
      await tester.tap(find.text('Kabari episode dan chapter baru'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('6 jam'));
      await tester.pumpAndSettle();
      expect(scheduler.scheduled, [2, 6]);
      expect(prefs.values[hoursKey], '6');
      await tester.tap(find.text('Kabari episode dan chapter baru'));
      await tester.pumpAndSettle();
      expect(scheduler.cancels, 1);
      expect(prefs.values[enabledKey], '0');
    },
  );
}
