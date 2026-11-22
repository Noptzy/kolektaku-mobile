import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/platform/haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<String> calls;

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('selection sends a selection click', () {
    const DeviceHaptics().selection();
    expect(calls, ['HapticFeedbackType.selectionClick']);
  });

  test('light sends a light impact', () {
    const DeviceHaptics().light();
    expect(calls, ['HapticFeedbackType.lightImpact']);
  });
}
