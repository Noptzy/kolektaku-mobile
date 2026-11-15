import '../../../src/rust/dto/settings.dart';

enum TranslationStatus { none, working, translated, failed }

const _trackLanguages = {
  TranslationLanguageDto.indonesian: 'id',
  TranslationLanguageDto.english: 'en',
  TranslationLanguageDto.malay: 'ms',
  TranslationLanguageDto.japanese: 'ja',
  TranslationLanguageDto.korean: 'ko',
  TranslationLanguageDto.chinese: 'zh',
  TranslationLanguageDto.arabic: 'ar',
  TranslationLanguageDto.thai: 'th',
  TranslationLanguageDto.vietnamese: 'vi',
  TranslationLanguageDto.filipino: 'fil',
  TranslationLanguageDto.spanish: 'es',
  TranslationLanguageDto.portuguese: 'pt',
  TranslationLanguageDto.french: 'fr',
  TranslationLanguageDto.german: 'de',
  TranslationLanguageDto.russian: 'ru',
  TranslationLanguageDto.hindi: 'hi',
  TranslationLanguageDto.turkish: 'tr',
};

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

String? trackLanguageOf(TranslationLanguageDto language) =>
    _trackLanguages[language];

bool translationIsOn(TranslationLanguageDto language) =>
    language != TranslationLanguageDto.off;

String translatedTitle(TranslationLanguageDto target) =>
    '${translationLanguageNames[target]} · terjemahan otomatis';

String translatingTitle(TranslationLanguageDto target) =>
    '${translationLanguageNames[target]} · Menerjemahkan…';

String clockLabel(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(time.hour)}.${two(time.minute)}';
}

String translationFailedNotice({int? retryAtSecs}) {
  if (retryAtSecs == null) {
    return 'Terjemahan belum berhasil, teks asli yang ditampilkan.';
  }
  final at = DateTime.fromMillisecondsSinceEpoch(retryAtSecs * 1000);
  return 'Layanan terjemahan sedang sibuk, dicoba lagi pukul ${clockLabel(at)}';
}
