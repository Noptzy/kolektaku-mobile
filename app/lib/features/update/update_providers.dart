import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/gateways/update_gateway.dart';
import '../../platform/apk_installer.dart';

final updateGatewayProvider = Provider<UpdateGateway>(
  (ref) => const BridgeUpdateGateway(),
);

final apkInstallerProvider = Provider<ApkInstaller>(
  (ref) => const ChannelApkInstaller(),
);

typedef FolderLookup = Future<String> Function();

final updateFolderProvider = Provider<FolderLookup>(
  (ref) =>
      () async => (await getTemporaryDirectory()).path,
);

typedef Seconds = int Function();

final nowSecondsProvider = Provider<Seconds>(
  (ref) =>
      () => DateTime.now().millisecondsSinceEpoch ~/ 1000,
);
