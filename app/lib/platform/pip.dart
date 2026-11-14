import 'dart:async';

import 'package:flutter/services.dart';

abstract class PipHost {
  Stream<bool> get modeChanges;

  Stream<void> get toggleRequests;

  Future<void> arm({required bool playing, int width = 16, int height = 9});

  Future<void> update({required bool playing});

  Future<void> disarm();

  Future<void> dispose();
}

class ChannelPipHost implements PipHost {
  ChannelPipHost({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName) {
    _channel.setMethodCallHandler(_handle);
  }

  static const channelName = 'app.kolektaku.mobile/pip';

  final MethodChannel _channel;
  final StreamController<bool> _modes = StreamController<bool>.broadcast();
  final StreamController<void> _toggles = StreamController<void>.broadcast();

  @override
  Stream<bool> get modeChanges => _modes.stream;

  @override
  Stream<void> get toggleRequests => _toggles.stream;

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'modeChanged':
        _modes.add(call.arguments == true);
      case 'action':
        if (call.arguments == 'toggle') _toggles.add(null);
    }
    return null;
  }

  Future<void> _invoke(String method, [Object? arguments]) async {
    try {
      await _channel.invokeMethod<Object>(method, arguments);
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> arm({required bool playing, int width = 16, int height = 9}) =>
      _invoke('arm', {'playing': playing, 'width': width, 'height': height});

  @override
  Future<void> update({required bool playing}) =>
      _invoke('update', {'playing': playing});

  @override
  Future<void> disarm() => _invoke('disarm');

  Future<bool> enterNow() async {
    try {
      return await _channel.invokeMethod<bool>('enterNow') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _modes.close();
    await _toggles.close();
  }
}
