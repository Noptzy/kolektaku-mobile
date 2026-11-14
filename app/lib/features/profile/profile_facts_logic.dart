import '../../src/rust/dto/profile_facts.dart';
import 'profile_logic.dart';

const _months = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const _genders = {
  'male': 'Laki-laki',
  'female': 'Perempuan',
  'non-binary': 'Non-biner',
};

const _languages = {
  'Japanese': 'Jepang',
  'English': 'Inggris',
  'Korean': 'Korea',
  'Chinese': 'Mandarin',
  'French': 'Prancis',
  'German': 'Jerman',
  'Italian': 'Italia',
  'Spanish': 'Spanyol',
  'Portuguese': 'Portugis',
};

String factLabel(FactKindDto kind) => switch (kind) {
  FactKindDto.occupations => 'Profesi',
  FactKindDto.birthday => 'Lahir',
  FactKindDto.died => 'Wafat',
  FactKindDto.age => 'Usia',
  FactKindDto.gender => 'Jenis kelamin',
  FactKindDto.bloodType => 'Golongan darah',
  FactKindDto.homeTown => 'Asal',
  FactKindDto.yearsActive => 'Aktif',
  FactKindDto.language => 'Bahasa',
  FactKindDto.nicknames => 'Nama lain',
  FactKindDto.studioType => 'Jenis',
  FactKindDto.favourites => 'Favorit',
};

String? _monthName(String number) {
  final index = int.tryParse(number);
  if (index == null || index < 1 || index > 12) return null;
  return _months[index - 1];
}

String _day(String number) => '${int.tryParse(number) ?? number}';

String dateText(String raw) {
  final full = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (full != null) {
    final month = _monthName(full[2]!);
    if (month != null) return '${_day(full[3]!)} $month ${full[1]}';
  }
  final noYear = RegExp(r'^--(\d{2})-(\d{2})$').firstMatch(raw);
  if (noYear != null) {
    final month = _monthName(noYear[1]!);
    if (month != null) return '${_day(noYear[2]!)} $month';
  }
  final noDay = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(raw);
  if (noDay != null) {
    final month = _monthName(noDay[2]!);
    if (month != null) return '$month ${noDay[1]}';
  }
  return raw;
}

String yearsText(String raw) {
  final parts = raw.split('-');
  if (parts.length != 2 || parts[0].isEmpty) return raw;
  return parts[1].isEmpty ? 'Sejak ${parts[0]}' : '${parts[0]} – ${parts[1]}';
}

String groupThousands(String digits) {
  if (int.tryParse(digits) == null) return digits;
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String factValue(ProfileFactDto fact) {
  final value = fact.value;
  return switch (fact.kind) {
    FactKindDto.birthday || FactKindDto.died => dateText(value),
    FactKindDto.gender => _genders[value.toLowerCase()] ?? value,
    FactKindDto.language => _languages[value] ?? value,
    FactKindDto.occupations =>
      value.split(', ').map(occupationLabel).join(', '),
    FactKindDto.yearsActive => yearsText(value),
    FactKindDto.favourites => groupThousands(value),
    FactKindDto.studioType => switch (value) {
      'animation' => 'Studio animasi',
      'producer' => 'Produser atau penerbit',
      _ => value,
    },
    FactKindDto.age ||
    FactKindDto.bloodType ||
    FactKindDto.homeTown ||
    FactKindDto.nicknames => value,
  };
}
