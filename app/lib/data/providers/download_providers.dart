import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/downloads/download_board.dart';
import '../../platform/download_device.dart';
import '../../src/rust/dto/downloads.dart';
import '../gateways/download_gateway.dart';

final downloadGatewayProvider = Provider<DownloadGateway>(
  (ref) => const BridgeDownloadGateway(),
);

final downloadDeviceProvider = Provider<DownloadDevice>(
  (ref) => ChannelDownloadDevice(),
);

final downloadsProvider = NotifierProvider<DownloadBoard, List<DownloadDto>>(
  DownloadBoard.new,
);

final downloadSettingsProvider = FutureProvider<DownloadSettingsDto>(
  (ref) => ref.watch(downloadGatewayProvider).settings(),
);
