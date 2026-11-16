import '../../src/rust/dto/credits.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

bool isUnreleased(String? status) =>
    status?.toUpperCase() == 'NOT_YET_RELEASED';

String? releaseDateLabel(DateDto? date) {
  final year = date?.year;
  if (date == null || year == null) return null;
  final month = date.month;
  if (month == null || month < 1 || month > 12) return '$year';
  final day = date.day;
  final name = _months[month - 1];
  return day == null ? '$name $year' : '$day $name $year';
}
