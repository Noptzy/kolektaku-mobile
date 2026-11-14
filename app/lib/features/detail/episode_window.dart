import '../../src/rust/dto/sources.dart';

const windowSize = 50;

class UnitWindow {
  const UnitWindow({required this.start, required this.end});

  final int start;
  final int end;

  String label(List<UnitDto> units) {
    final first = units[start].number;
    final last = units[end - 1].number;
    return '${_text(first)}-${_text(last)}';
  }

  static String _text(double number) =>
      number == number.roundToDouble() ? '${number.round()}' : '$number';
}

List<UnitDto> sortedUnits(List<UnitDto> units, {required bool descending}) {
  final copy = [...units]..sort((a, b) => a.number.compareTo(b.number));
  return descending ? copy.reversed.toList() : copy;
}

List<UnitWindow> windowsFor(int count) {
  if (count <= windowSize) return const [];
  return [
    for (var start = 0; start < count; start += windowSize)
      UnitWindow(
        start: start,
        end: start + windowSize > count ? count : start + windowSize,
      ),
  ];
}

int windowIndexOf(List<UnitDto> sorted, double number) {
  final at = sorted.indexWhere((unit) => unit.number == number);
  return at < 0 ? 0 : at ~/ windowSize;
}

int? indexOfNumber(List<UnitDto> sorted, double number) {
  final at = sorted.indexWhere((unit) => unit.number == number);
  return at < 0 ? null : at;
}

UnitDto? firstUnit(List<UnitDto> units) {
  if (units.isEmpty) return null;
  return sortedUnits(units, descending: false).first;
}

UnitDto? unitAfter(List<UnitDto> units, double number) {
  final ordered = sortedUnits(units, descending: false);
  for (final unit in ordered) {
    if (unit.number > number) return unit;
  }
  return null;
}

UnitDto? unitBefore(List<UnitDto> units, double number) {
  final ordered = sortedUnits(units, descending: false);
  UnitDto? found;
  for (final unit in ordered) {
    if (unit.number >= number) break;
    found = unit;
  }
  return found;
}
