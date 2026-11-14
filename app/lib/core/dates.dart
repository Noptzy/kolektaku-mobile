import '../src/rust/dto/credits.dart';

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

String? formatDate(DateDto date) {
  final year = date.year;
  if (year == null) return null;
  final month = date.month;
  if (month == null || month < 1 || month > 12) return '$year';
  final day = date.day;
  final name = _months[month - 1];
  return day == null ? '$name $year' : '$day $name $year';
}

String formatAiring(BigInt epochSeconds) {
  final time = DateTime.fromMillisecondsSinceEpoch(
    epochSeconds.toInt() * 1000,
    isUtc: true,
  ).toLocal();
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '${time.day} ${_months[time.month - 1]} ${time.year}, $hour.$minute';
}
