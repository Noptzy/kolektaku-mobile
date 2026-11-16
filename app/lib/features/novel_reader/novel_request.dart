import '../../src/rust/dto/media.dart';

class NovelRequest {
  const NovelRequest({
    required this.reference,
    required this.title,
    required this.chapter,
    this.coverUrl,
    this.preferredSource,
    this.block,
  });

  final MediaRefDto reference;
  final String title;
  final double chapter;
  final String? coverUrl;
  final String? preferredSource;
  final int? block;

  NovelRequest copyWith({double? chapter, String? preferredSource}) {
    return NovelRequest(
      reference: reference,
      title: title,
      chapter: chapter ?? this.chapter,
      coverUrl: coverUrl,
      preferredSource: preferredSource ?? this.preferredSource,
      block: chapter == null ? block : null,
    );
  }
}
