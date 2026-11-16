import '../../src/rust/dto/follow.dart';
import '../../src/rust/dto/media.dart';
import '../detail/detail_request.dart';

const maxSeparateNotices = 3;

String _number(double value) =>
    value == value.roundToDouble() ? '${value.round()}' : '$value';

String noticeBody(UpdateEventDto event) {
  final number = _number(event.unitNumber);
  return switch (event.kind) {
    MediaKindDto.anime => 'Episode $number sudah tayang',
    MediaKindDto.manga => 'Chapter $number sudah terbit',
    MediaKindDto.novel => 'Chapter $number sudah terbit',
  };
}

String summaryTitle(int count) => '$count judul favoritmu ada yang baru';

String summaryBody(List<UpdateEventDto> events) {
  final names = events.take(4).map((event) => event.title).join(', ');
  return events.length > 4 ? '$names, dan lainnya' : names;
}

String payloadOf(UpdateEventDto event) {
  final reference = event.reference;
  return [
    event.kind.name,
    reference.kind.name,
    reference.id.toString(),
    reference.source,
    reference.item,
  ].join('|');
}

DetailRequest? requestFromPayload(String? payload) {
  final parts = payload?.split('|');
  if (parts == null || parts.length != 5) return null;
  final kind = MediaKindDto.values.where((value) => value.name == parts[0]);
  final refKind = MediaRefKind.values.where((value) => value.name == parts[1]);
  final id = BigInt.tryParse(parts[2]);
  if (kind.isEmpty || refKind.isEmpty || id == null) return null;
  return DetailRequest(
    kind: kind.first,
    reference: MediaRefDto(
      kind: refKind.first,
      id: id,
      source: parts[3],
      item: parts[4],
    ),
  );
}
