import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/keep_for.dart';

const _lifetime = Duration(milliseconds: 120);
const _short = Duration(milliseconds: 20);
const _long = Duration(milliseconds: 240);

void main() {
  late ProviderContainer container;
  late int builds;
  late FutureProvider<int> kept;
  late FutureProvider<int> plain;

  setUp(() {
    container = ProviderContainer();
    builds = 0;
    kept = FutureProvider.autoDispose<int>((ref) {
      ref.keepFor(_lifetime);
      return ++builds;
    });
    plain = FutureProvider.autoDispose<int>((ref) => ++builds);
  });

  tearDown(() => container.dispose());

  Future<void> visit(FutureProvider<int> provider) async {
    final subscription = container.listen(provider, (previous, next) {});
    await container.pump();
    subscription.close();
    await container.pump();
  }

  test('a kept provider answers again without rebuilding', () async {
    await visit(kept);
    await Future<void>.delayed(_short);
    await visit(kept);
    expect(builds, 1);
  });

  test('a kept provider rebuilds once its lifetime is over', () async {
    await visit(kept);
    await Future<void>.delayed(_long);
    await visit(kept);
    expect(builds, 2);
  });

  test('without keepFor the state goes as soon as nobody listens', () async {
    await visit(plain);
    await Future<void>.delayed(_short);
    await visit(plain);
    expect(builds, 2);
  });

  test('invalidating a kept provider rebuilds it right away', () async {
    final subscription = container.listen(kept, (previous, next) {});
    await container.pump();
    container.invalidate(kept);
    await container.pump();
    expect(builds, 2);
    subscription.close();
  });
}
