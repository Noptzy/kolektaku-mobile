import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/controls_visibility.dart';

void main() {
  testWidgets('hide after three seconds while playing', (tester) async {
    final controls = ControlsVisibility(isPlaying: () => true);
    addTearDown(controls.dispose);
    controls.schedule();
    await tester.pump(const Duration(seconds: 2));
    expect(controls.visible, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(controls.visible, isFalse);
  });

  testWidgets('never hide while paused', (tester) async {
    final controls = ControlsVisibility(isPlaying: () => false);
    addTearDown(controls.dispose);
    controls.schedule();
    await tester.pump(const Duration(seconds: 10));
    expect(controls.visible, isTrue);
  });

  testWidgets('toggle shows again and starts a new countdown', (tester) async {
    final controls = ControlsVisibility(isPlaying: () => true);
    addTearDown(controls.dispose);
    controls.toggle();
    expect(controls.visible, isFalse);
    controls.toggle();
    expect(controls.visible, isTrue);
    await tester.pump(const Duration(seconds: 3));
    expect(controls.visible, isFalse);
  });

  testWidgets('interacting while hidden brings them back', (tester) async {
    final controls = ControlsVisibility(isPlaying: () => true);
    addTearDown(controls.dispose);
    controls.toggle();
    controls.interacted();
    expect(controls.visible, isTrue);
  });

  testWidgets('interacting restarts the countdown', (tester) async {
    final controls = ControlsVisibility(isPlaying: () => true);
    addTearDown(controls.dispose);
    controls.schedule();
    await tester.pump(const Duration(seconds: 2));
    controls.interacted();
    await tester.pump(const Duration(seconds: 2));
    expect(controls.visible, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(controls.visible, isFalse);
  });

  testWidgets('listeners hear only real changes and dispose is safe', (
    tester,
  ) async {
    final controls = ControlsVisibility(isPlaying: () => true);
    var heard = 0;
    controls.addListener(() => heard++);
    controls.interacted();
    expect(heard, 0);
    controls.toggle();
    expect(heard, 1);
    controls.dispose();
    await tester.pump(const Duration(seconds: 10));
  });
}
