import '../src/rust/dto/cards.dart';

String mediaMeta(MediaCardDto card, {String unitLabel = 'eps'}) {
  final parts = <String>[];
  final year = card.year;
  final units = card.unitCount;
  if (year != null) parts.add('$year');
  if (units != null) parts.add('$units $unitLabel');
  final latest = card.latestLabel;
  if (parts.isEmpty && latest != null) parts.add(latest);
  return parts.join(' · ');
}
