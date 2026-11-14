import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../src/rust/api/session.dart' as core;

Future<void> startCore() async {
  final folder = await getApplicationSupportDirectory();
  final info = await PackageInfo.fromPlatform();
  await core.init(appDir: folder.path, appVersion: info.version);
}
