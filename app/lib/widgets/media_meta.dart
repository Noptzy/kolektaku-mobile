import '../src/rust/dto/cards.dart';

const _comicFormats = {'MANGA', 'NOVEL', 'ONE_SHOT'};

String unitLabelOf(MediaCardDto card) =>
    _comicFormats.contains(card.format?.toUpperCase()) ? 'chapter' : 'eps';

String mediaMeta(MediaCardDto card, {String? unitLabel}) {
  final parts = <String>[];
  final year = card.year;
  final units = card.unitCount;
  if (year != null) parts.add('$year');
  if (units != null) parts.add('$units ${unitLabel ?? unitLabelOf(card)}');
  final latest = card.latestLabel;
  if (parts.isEmpty && latest != null) parts.add(latest);
  return parts.join(' · ');
}
