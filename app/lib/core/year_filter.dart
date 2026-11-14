const recentYearCount = 12;

class YearFilter {
  const YearFilter.only(this.year) : orOlder = false;

  const YearFilter.upTo(this.year) : orOlder = true;

  final int year;
  final bool orOlder;

  int? get fromYear => orOlder ? null : year;

  int get toYear => year;

  bool accepts(int? value) {
    if (value == null) return false;
    return orOlder ? value <= year : value == year;
  }

  String get id => orOlder ? 'le$year' : '$year';

  String get label => orOlder ? '$year dan lebih lama' : '$year';

  static YearFilter? parse(String id) {
    if (id.startsWith('le')) {
      final year = int.tryParse(id.substring(2));
      return year == null ? null : YearFilter.upTo(year);
    }
    final year = int.tryParse(id);
    return year == null ? null : YearFilter.only(year);
  }

  @override
  bool operator ==(Object other) =>
      other is YearFilter && other.year == year && other.orOlder == orOlder;

  @override
  int get hashCode => Object.hash(year, orOlder);
}

List<YearFilter> yearOptions(int currentYear) {
  return [
    for (var year = currentYear; year > currentYear - recentYearCount; year--)
      YearFilter.only(year),
    YearFilter.upTo(currentYear - recentYearCount),
  ];
}
