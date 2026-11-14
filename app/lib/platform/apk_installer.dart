import 'package:flutter/services.dart';

abstract interface class ApkInstaller {
  Future<List<String>> abis();

  Future<void> install(String path);
}

class InstallFailure implements Exception {
  const InstallFailure(this.reason);

  final String reason;

  @override
  String toString() => 'InstallFailure($reason)';
}

class ChannelApkInstaller implements ApkInstaller {
  const ChannelApkInstaller({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'app.kolektaku.mobile/apk_installer';

  final MethodChannel _channel;

  @override
  Future<List<String>> abis() async {
    try {
      final found = await _channel.invokeListMethod<String>('abis');
      return found ?? const [];
    } on MissingPluginException {
      return const [];
    }
  }

  @override
  Future<void> install(String path) async {
    try {
      await _channel.invokeMethod<void>('install', {'path': path});
    } on PlatformException catch (error) {
      throw InstallFailure(error.message ?? error.code);
    } on MissingPluginException {
      throw const InstallFailure('pemasang tidak tersedia');
    }
  }
}
