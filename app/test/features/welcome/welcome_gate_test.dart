import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/features/welcome/welcome_gate.dart';
import 'package:kolektaku/features/welcome/welcome_store.dart';

class _Store implements WelcomeStore {
  _Store({required this.hasSeen});

  bool hasSeen;
  int marks = 0;

  @override
  Future<bool> seen() async => hasSeen;

  @override
  Future<void> markSeen() async {
    marks++;
    hasSeen = true;
  }
}

void main() {
  group('WelcomeGate', () {
    test('starts not pending', () {
      expect(WelcomeGate().pending, isFalse);
    });

    test(
      'loading an unseen store makes it pending and tells listeners',
      () async {
        final gate = WelcomeGate();
        var told = 0;
        gate.addListener(() => told++);
        await gate.load(_Store(hasSeen: false));
        expect(gate.pending, isTrue);
        expect(told, 1);
      },
    );

    test('loading a seen store stays quiet', () async {
      final gate = WelcomeGate();
      var told = 0;
      gate.addListener(() => told++);
      await gate.load(_Store(hasSeen: true));
      expect(gate.pending, isFalse);
      expect(told, 0);
    });

    test('completing clears it once and does not repeat', () async {
      final gate = WelcomeGate(pending: true);
      var told = 0;
      gate.addListener(() => told++);
      gate.complete();
      gate.complete();
      expect(gate.pending, isFalse);
      expect(told, 1);
    });
  });

  group('welcomeRedirect', () {
    test('sends the home page to the welcome while it is pending', () {
      expect(
        welcomeRedirect(WelcomeGate(pending: true), Routes.home),
        Routes.welcome,
      );
    });

    test('leaves every other page alone, so deep links still open', () {
      final gate = WelcomeGate(pending: true);
      for (final route in [
        Routes.sceneSearch,
        Routes.detail,
        Routes.collection,
        Routes.welcome,
      ]) {
        expect(welcomeRedirect(gate, route), isNull, reason: route);
      }
    });

    test('does nothing once the welcome has been seen', () {
      expect(welcomeRedirect(WelcomeGate(), Routes.home), isNull);
    });
  });
}
