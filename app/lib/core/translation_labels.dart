import '../src/rust/dto/settings.dart';

const translationLanguageNames = {
  TranslationLanguageDto.off: 'Mati',
  TranslationLanguageDto.indonesian: 'Indonesia',
  TranslationLanguageDto.english: 'Inggris',
  TranslationLanguageDto.malay: 'Melayu',
  TranslationLanguageDto.japanese: 'Jepang',
  TranslationLanguageDto.korean: 'Korea',
  TranslationLanguageDto.chinese: 'Mandarin',
  TranslationLanguageDto.arabic: 'Arab',
  TranslationLanguageDto.thai: 'Thai',
  TranslationLanguageDto.vietnamese: 'Vietnam',
  TranslationLanguageDto.filipino: 'Filipino',
  TranslationLanguageDto.spanish: 'Spanyol',
  TranslationLanguageDto.portuguese: 'Portugis',
  TranslationLanguageDto.french: 'Prancis',
  TranslationLanguageDto.german: 'Jerman',
  TranslationLanguageDto.russian: 'Rusia',
  TranslationLanguageDto.hindi: 'Hindi',
  TranslationLanguageDto.turkish: 'Turki',
};

String clockLabel(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.hour)}.${two(time.minute)}';
}

String clockLabelOfSecs(int epochSecs) =>
    clockLabel(DateTime.fromMillisecondsSinceEpoch(epochSecs * 1000));
