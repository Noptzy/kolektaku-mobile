import 'episode_loader.dart';

typedef HeldEpisode = ({
  LoadedEpisode episode,
  Duration position,
  int generation,
});

class ResumeGate {
  HeldEpisode? _held;

  Duration? get waitingFor => _held?.position;

  void hold(LoadedEpisode episode, Duration position, int generation) {
    _held = (episode: episode, position: position, generation: generation);
  }

  HeldEpisode? release() {
    final held = _held;
    _held = null;
    return held;
  }

  void clear() => _held = null;

  Future<void> settle({
    required bool resume,
    required Future<void> Function(LoadedEpisode, Duration, int) begin,
    required bool Function(int generation) isCurrent,
    required void Function(Object failure) onError,
  }) async {
    final held = release();
    if (held == null || !isCurrent(held.generation)) return;
    try {
      await begin(
        held.episode,
        resume ? held.position : Duration.zero,
        held.generation,
      );
    } on Object catch (failure) {
      if (isCurrent(held.generation)) onError(failure);
    }
  }
}
