import '../../src/rust/dto/update.dart';

enum UpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  ready,
  installing,
  failed,
}

class UpdateState {
  const UpdateState({
    this.phase = UpdatePhase.idle,
    this.offer,
    this.received = 0,
    this.total = 0,
    this.path,
    this.error,
    this.installed,
  });

  final UpdatePhase phase;
  final UpdateOfferDto? offer;
  final int received;
  final int total;
  final String? path;
  final String? error;
  final String? installed;

  bool get busy =>
      phase == UpdatePhase.checking ||
      phase == UpdatePhase.downloading ||
      phase == UpdatePhase.installing;

  bool get isRequired => offer?.required_ ?? false;

  bool get hasOffer => offer != null;

  double? get fraction =>
      total <= 0 ? null : (received / total).clamp(0.0, 1.0);

  UpdateState copyWith({
    UpdatePhase? phase,
    int? received,
    int? total,
    String? path,
    String? error,
  }) {
    return UpdateState(
      phase: phase ?? this.phase,
      offer: offer,
      received: received ?? this.received,
      total: total ?? this.total,
      path: path ?? this.path,
      error: error,
      installed: installed,
    );
  }
}
