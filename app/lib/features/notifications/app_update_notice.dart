import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../platform/apk_installer.dart';
import '../../platform/notifier.dart';
import '../../src/rust/api/update.dart' as update;
import 'notification_prefs.dart';

String appUpdateTitle(String version) => 'Kolektaku $version tersedia';

String appUpdateBody({required bool required_}) => required_
    ? 'Pembaruan penting. Buka aplikasi untuk memasangnya.'
    : 'Buka aplikasi untuk memasang versi terbaru.';

Future<void> announceNewVersion(Notifier notifier) async {
  try {
    final info = await PackageInfo.fromPlatform();
    final abis = await const ChannelApkInstaller().abis();
    final offer = await update.checkUpdate(installed: info.version, abis: abis);
    if (offer == null) return;
    if (await NotificationPrefs.notifiedVersion() == offer.version) return;
    await notifier.showNotice(
      title: appUpdateTitle(offer.version),
      body: appUpdateBody(required_: offer.required_),
    );
    await NotificationPrefs.setNotifiedVersion(offer.version);
  } on Object {
    debugPrint('app update notice skipped');
  }
}
