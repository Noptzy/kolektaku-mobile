import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/auto_next.dart';

void main() {
  testWidgets('counts down five seconds then plays once', (tester) async {
    var played = 0;
    final auto = AutoNext(onElapsed: () => played++);
    addTearDown(auto.dispose);
    auto.start();
    expect(auto.active, isTrue);
    expect(auto.remaining, 5);
    await tester.pump(const Duration(seconds: 1));
    expect(auto.remaining, 4);
    await tester.pump(const Duration(seconds: 3));
    expect(auto.remaining, 1);
    expect(played, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(played, 1);
    expect(auto.active, isFalse);
    await tester.pump(const Duration(seconds: 10));
    expect(played, 1);
  });

  testWidgets('cancel stops the countdown without playing', (tester) async {
    var played = 0;
    final auto = AutoNext(onElapsed: () => played++);
    addTearDown(auto.dispose);
    auto.start();
    await tester.pump(const Duration(seconds: 2));
    auto.cancel();
    await tester.pump(const Duration(seconds: 10));
    expect(played, 0);
    expect(auto.active, isFalse);
    expect(auto.remaining, 0);
  });

  testWidgets('now plays at once and stops the timer', (tester) async {
    var played = 0;
    final auto = AutoNext(onElapsed: () => played++);
    addTearDown(auto.dispose);
    auto.start();
    auto.now();
    expect(played, 1);
    await tester.pump(const Duration(seconds: 10));
    expect(played, 1);
  });

  testWidgets('starting again restarts from the full delay', (tester) async {
    final auto = AutoNext(onElapsed: () {});
    addTearDown(auto.dispose);
    auto.start();
    await tester.pump(const Duration(seconds: 3));
    auto.start();
    expect(auto.remaining, 5);
  });

  testWidgets('listeners hear every tick and the end', (tester) async {
    final auto = AutoNext(onElapsed: () {}, delay: const Duration(seconds: 2));
    addTearDown(auto.dispose);
    var heard = 0;
    auto.addListener(() => heard++);
    auto.start();
    await tester.pump(const Duration(seconds: 2));
    expect(heard, 3);
  });

  testWidgets('cancel when idle is silent and dispose is safe', (tester) async {
    final auto = AutoNext(onElapsed: () {});
    var heard = 0;
    auto.addListener(() => heard++);
    auto.cancel();
    expect(heard, 0);
    auto.start();
    auto.dispose();
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('a custom delay is respected', (tester) async {
    var played = 0;
    final auto = AutoNext(
      onElapsed: () => played++,
      delay: const Duration(seconds: 2),
    );
    addTearDown(auto.dispose);
    auto.start();
    await tester.pump(const Duration(seconds: 2));
    expect(played, 1);
  });
}
