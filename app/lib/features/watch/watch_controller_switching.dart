part of 'watch_controller.dart';

extension WatchSwitching on WatchController {
  Future<void> chooseResume({required bool resume}) => _gate.settle(
    resume: resume,
    begin: _begin,
    isCurrent: (generation) => generation == _generation && !_disposed,
    onError: (failure) {
      error = failure;
      _notify();
    },
  );

  Future<void> useServer(String serverId) async {
    final current = loaded;
    final position = _position;
    if (current == null || current.serverId == serverId) return;
    final generation = ++_generation;
    try {
      final next = await loader.useServer(current, serverId);
      if (generation != _generation) return;
      await _teardown();
      await _begin(next, position ?? Duration.zero, generation);
    } on Object catch (failure) {
      if (generation != _generation || _disposed) return;
      error = failure;
      _notify();
    }
  }

  Duration? get _position => session?.engine.snapshot.value.position;

  Future<void> useSource(String source) {
    request = request.copyWith(preferredSource: source);
    return load(startAt: _position);
  }

  Future<void> tryOtherSource() {
    final current = loaded;
    if (current == null) return load();
    return load(exclude: [current.playback.source], startAt: _position);
  }
}
