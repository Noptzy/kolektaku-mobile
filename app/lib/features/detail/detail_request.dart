import '../../src/rust/dto/media.dart';

class DetailRequest {
  const DetailRequest({
    required this.kind,
    required this.reference,
    this.notice,
  });

  factory DetailRequest.catalog(MediaSummaryDto summary) {
    return DetailRequest(
      kind: summary.kind,
      reference: MediaRefDto(
        kind: MediaRefKind.catalog,
        id: summary.id,
        source: '',
        item: '',
      ),
    );
  }

  final MediaKindDto kind;
  final MediaRefDto reference;
  final String? notice;

  @override
  bool operator ==(Object other) =>
      other is DetailRequest &&
      other.kind == kind &&
      other.reference == reference &&
      other.notice == notice;

  @override
  int get hashCode => Object.hash(kind, reference, notice);
}
