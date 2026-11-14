import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/core/ttl_cache.dart';

class FakeClock {
  DateTime now = DateTime(2026, 11, 14, 12);

  void advance(Duration by) => now = now.add(by);
}

void main() {
  late FakeClock clock;
  late TtlCache<String, int> cache;

  setUp(() {
    clock = FakeClock();
    cache = TtlCache(
      lifetime: const Duration(minutes: 5),
      capacity: 3,
      now: () => clock.now,
    );
  });

  test('a stored value comes back until its lifetime is over', () {
    cache.put('a', 1);
    clock.advance(const Duration(minutes: 4, seconds: 59));
    expect(cache.get('a'), 1);
    clock.advance(const Duration(seconds: 1));
    expect(cache.get('a'), isNull);
  });

  test('an unknown key is a miss', () {
    expect(cache.get('nothing'), isNull);
  });

  test('an expired value is dropped, not just hidden', () {
    cache.put('a', 1);
    clock.advance(const Duration(minutes: 6));
    cache.get('a');
    expect(cache.length, 0);
  });

  test('putting again replaces the value and restarts its lifetime', () {
    cache.put('a', 1);
    clock.advance(const Duration(minutes: 4));
    cache.put('a', 2);
    clock.advance(const Duration(minutes: 4));
    expect(cache.get('a'), 2);
  });

  test('the oldest entry goes first when the cache is full', () {
    cache
      ..put('a', 1)
      ..put('b', 2)
      ..put('c', 3)
      ..put('d', 4);
    expect(cache.get('a'), isNull);
    expect([cache.get('b'), cache.get('c'), cache.get('d')], [2, 3, 4]);
    expect(cache.length, 3);
  });

  test('refreshing an entry makes it the newest one', () {
    cache
      ..put('a', 1)
      ..put('b', 2)
      ..put('c', 3)
      ..put('a', 10)
      ..put('d', 4);
    expect(cache.get('b'), isNull);
    expect(cache.get('a'), 10);
  });

  test('remove forgets one key and clear forgets all', () {
    cache
      ..put('a', 1)
      ..put('b', 2)
      ..remove('a');
    expect(cache.get('a'), isNull);
    expect(cache.get('b'), 2);
    cache.clear();
    expect(cache.length, 0);
  });
}
