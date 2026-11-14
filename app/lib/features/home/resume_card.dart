import '../../src/rust/dto/cards.dart';
import '../../src/rust/dto/library.dart';
import '../../src/rust/dto/media.dart';

String unitText(double number) =>
    number == number.roundToDouble() ? '${number.round()}' : '$number';

String resumeMeta(MediaKindDto kind, double unitNumber) {
  final name = kind == MediaKindDto.anime ? 'Episode' : 'Chapter';
  return '$name ${unitText(unitNumber)}';
}

double? resumeFraction(ProgressDto progress) {
  if (progress.length <= 0) return null;
  return (progress.position / progress.length).clamp(0.0, 1.0);
}

MediaCardDto resumeCard(ProgressDto progress) {
  return MediaCardDto(
    reference: progress.reference,
    title: progress.title,
    coverUrl: progress.coverUrl,
    latestLabel: resumeMeta(progress.kind, progress.unitNumber),
    genres: const [],
    limited: false,
    sources: const [],
  );
}
