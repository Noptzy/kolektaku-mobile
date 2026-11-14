mixin FakeCacheClearing {
  int cacheClears = 0;

  Future<void> clearCache() async {
    cacheClears++;
  }
}
