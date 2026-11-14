typedef Clock = DateTime Function();

class TtlCache<K, V> {
  TtlCache({required this.lifetime, this.capacity = 48, Clock? now})
    : _now = now ?? DateTime.now;

  final Duration lifetime;
  final int capacity;
  final Clock _now;
  final Map<K, (V, DateTime)> _entries = {};

  int get length => _entries.length;

  V? get(K key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (_now().difference(entry.$2) >= lifetime) {
      _entries.remove(key);
      return null;
    }
    return entry.$1;
  }

  void put(K key, V value) {
    _entries.remove(key);
    _entries[key] = (value, _now());
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void remove(K key) => _entries.remove(key);

  void clear() => _entries.clear();
}
