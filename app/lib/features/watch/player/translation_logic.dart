import '../../../core/translation_labels.dart';
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

String? trackLanguageOf(TranslationLanguageDto language) =>
    _trackLanguages[language];

bool translationIsOn(TranslationLanguageDto language) =>
    language != TranslationLanguageDto.off;

String translatedTitle(TranslationLanguageDto target) =>
    '${translationLanguageNames[target]} · terjemahan otomatis';

String translatingTitle(TranslationLanguageDto target) =>
    '${translationLanguageNames[target]} · Menerjemahkan…';

String translationFailedNotice({int? retryAtSecs}) {
  if (retryAtSecs == null) {
    return 'Terjemahan belum berhasil, teks asli yang ditampilkan.';
  }
  return 'Layanan terjemahan sedang sibuk, dicoba lagi pukul '
      '${clockLabelOfSecs(retryAtSecs)}';
}
