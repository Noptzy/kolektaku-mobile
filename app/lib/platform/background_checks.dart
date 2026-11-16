import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../data/core_session.dart';
import '../features/notifications/app_update_notice.dart';
import '../features/notifications/notification_prefs.dart';
import '../src/rust/api/follow.dart' as follow;
import '../src/rust/frb_generated.dart';
import 'notifier.dart';

const _uniqueName = 'kolektaku-followed-check';
const _taskName = 'kolektaku.followed.check';

Future<bool> runBackgroundCheck({Notifier? notifier}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await startCore();
  if (!await NotificationPrefs.enabled()) return true;
  final shown = notifier ?? LocalNotifier();
  await shown.init();
  try {
    await shown.showEvents(await follow.checkFollowedUpdates());
  } on Object {
    // A failed round is simply tried again at the next interval.
  }
  await announceNewVersion(shown);
  return true;
}

@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, input) => runBackgroundCheck());
}

abstract interface class ChecksScheduler {
  Future<void> schedule(int hours);

  Future<void> cancel();
}

class WorkmanagerScheduler implements ChecksScheduler {
  const WorkmanagerScheduler();

  @override
  Future<void> schedule(int hours) async {
    await Workmanager().initialize(backgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      _uniqueName,
      _taskName,
      frequency: Duration(hours: hours),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  @override
  Future<void> cancel() async {
    await Workmanager().initialize(backgroundDispatcher);
    await Workmanager().cancelByUniqueName(_uniqueName);
  }
}

ChecksScheduler checksScheduler = const WorkmanagerScheduler();

Future<void> scheduleChecks(int hours) => checksScheduler.schedule(hours);

Future<void> cancelChecks() => checksScheduler.cancel();
