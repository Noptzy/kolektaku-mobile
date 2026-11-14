import 'package:flutter/services.dart';

abstract class ScreenAwake {
  Future<void> keepOn(bool on);
}

class ChannelScreenAwake implements ScreenAwake {
  ChannelScreenAwake({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'app.kolektaku.mobile/awake';

  final MethodChannel _channel;

  @override
  Future<void> keepOn(bool on) async {
    try {
      await _channel.invokeMethod<void>('keepOn', on);
    } on MissingPluginException {
      return;
    }
  }
}
