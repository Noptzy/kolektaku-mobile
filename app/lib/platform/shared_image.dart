import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class SharedImages {
  Future<Uint8List?> take();
}

class ChannelSharedImages implements SharedImages {
  const ChannelSharedImages();

  static const channelName = 'app.kolektaku.mobile/share';
  static const _channel = MethodChannel(channelName);

  @override
  Future<Uint8List?> take() async {
    try {
      return await _channel.invokeMethod<Uint8List>('takeSharedImage');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}

final sharedImagesProvider = Provider<SharedImages>(
  (ref) => const ChannelSharedImages(),
);
