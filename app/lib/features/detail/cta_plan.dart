import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';
import '../../src/rust/dto/sources.dart';
import 'episode_window.dart';

class CtaPlan {
  const CtaPlan({
    required this.label,
    this.unit,
    this.startAt,
    this.enabled = true,
  });

  final String label;
  final UnitDto? unit;
  final Duration? startAt;
  final bool enabled;
}

String _number(double value) =>
    value == value.roundToDouble() ? '${value.round()}' : '$value';

CtaPlan planCta({
  required MediaKindDto kind,
  required List<UnitDto> units,
  required ProgressDto? last,
  required bool isFilm,
  bool unreleased = false,
  String? releaseLabel,
}) {
  final anime = kind == MediaKindDto.anime;
  if (unreleased) {
    return CtaPlan(
      label: releaseLabel == null
          ? 'Belum tayang'
          : 'Belum tayang · $releaseLabel',
      enabled: false,
    );
  }
  if (units.isEmpty) {
    return const CtaPlan(label: 'Belum ada sumber', enabled: false);
  }
  final ordered = sortedUnits(units, descending: false);
  String start(UnitDto unit) {
    if (anime && isFilm) return 'Tonton film';
    return anime
        ? 'Tonton Episode ${_number(unit.number)}'
        : 'Baca Chapter ${_number(unit.number)}';
  }

  if (last == null) {
    return CtaPlan(label: start(ordered.first), unit: ordered.first);
  }
  final resumed = ordered.where((unit) => unit.number == last.unitNumber);
  if (!last.completed && resumed.isNotEmpty) {
    final unit = resumed.first;
    final seconds = last.position.round();
    return CtaPlan(
      label: anime
          ? 'Lanjut Ep. ${_number(unit.number)}'
          : 'Lanjut Ch. ${_number(unit.number)}',
      unit: unit,
      startAt: anime && seconds > 0 ? Duration(seconds: seconds) : null,
    );
  }
  final next = unitAfter(units, last.unitNumber);
  if (next != null) return CtaPlan(label: start(next), unit: next);
  return CtaPlan(label: 'Tonton dari awal', unit: ordered.first);
}
