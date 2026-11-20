import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

abstract interface class DownloadDevice {
  Future<void> keepAlive({
    required bool active,
    String title = '',
    String text = '',
    int progress = -1,
  });

  Future<String?> publish(String path);

  Future<bool> delete(String target);

  Future<bool> open(String target, String name);

  Future<String?> folder();
}

class ChannelDownloadDevice implements DownloadDevice {
  ChannelDownloadDevice({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'app.kolektaku.mobile/downloads';

  final MethodChannel _channel;

  Future<T?> _call<T>(String method, Map<String, Object?> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> keepAlive({
    required bool active,
    String title = '',
    String text = '',
    int progress = -1,
  }) => _call<void>('keepAlive', {
    'active': active,
    'title': title,
    'text': text,
    'progress': progress,
  });

  @override
  Future<String?> publish(String path) =>
      _call<String>('publish', {'path': path});

  @override
  Future<bool> delete(String target) async =>
      await _call<bool>('delete', {'target': target}) ?? false;

  @override
  Future<bool> open(String target, String name) async =>
      await _call<bool>('open', {'target': target, 'name': name}) ?? false;

  @override
  Future<String?> folder() async {
    try {
      final external = await getExternalStorageDirectory();
      final base = external ?? await getApplicationDocumentsDirectory();
      return '${base.path}/Unduhan';
    } on Object {
      return null;
    }
  }
}
