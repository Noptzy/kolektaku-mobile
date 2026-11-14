import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/platform/pip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ChannelPipHost.channelName);
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return true;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<void> fromNative(String method, Object? arguments) async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          channel.codec.encodeMethodCall(MethodCall(method, arguments)),
          (_) {},
        );
  }

  test('arming sends the aspect ratio and the playing state', () async {
    final host = ChannelPipHost();
    await host.arm(playing: true, width: 4, height: 3);
    expect(calls.single.method, 'arm');
    expect(calls.single.arguments, {'playing': true, 'width': 4, 'height': 3});
    await host.dispose();
  });

  test('updating and disarming reach the native side', () async {
    final host = ChannelPipHost();
    await host.update(playing: false);
    await host.disarm();
    expect(calls.map((call) => call.method), ['update', 'disarm']);
    expect(calls.first.arguments, {'playing': false});
    await host.dispose();
  });

  test('mode changes and the toggle action arrive as streams', () async {
    final host = ChannelPipHost();
    final modes = <bool>[];
    var toggles = 0;
    host.modeChanges.listen(modes.add);
    host.toggleRequests.listen((_) => toggles++);
    await fromNative('modeChanged', true);
    await fromNative('action', 'toggle');
    await fromNative('action', 'something-else');
    await fromNative('modeChanged', false);
    await Future<void>.delayed(Duration.zero);
    expect(modes, [true, false]);
    expect(toggles, 1);
    await host.dispose();
  });

  test('a missing native plugin is not an error', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    final host = ChannelPipHost();
    await host.arm(playing: true);
    expect(await host.enterNow(), isFalse);
    await host.dispose();
  });
}
