import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/notifications/notification_prefs.dart';
import 'package:kolektaku/platform/background_checks.dart';
import 'package:kolektaku/features/settings/notification_section.dart';

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

Future<FakeNotifier> open(
  WidgetTester tester, {
  bool permitted = true,
  bool grants = true,
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
    SingleChildScrollView(child: NotificationSection(notifier: notifier)),
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

  testWidgets('the test button plays the sound only when allowed', (
    tester,
  ) async {
    final notifier = await open(tester);
    await tester.tap(find.byKey(const Key('notify-test')));
    await tester.pump();
    expect(notifier.tests, 1);
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
