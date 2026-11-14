import '../../src/rust/dto/media.dart';

class ReadRequest {
  const ReadRequest({
    required this.reference,
    required this.title,
    required this.chapter,
    this.coverUrl,
    this.preferredSource,
  });

  final MediaRefDto reference;
  final String title;
  final double chapter;
  final String? coverUrl;
  final String? preferredSource;

  ReadRequest copyWith({double? chapter, String? preferredSource}) {
    return ReadRequest(
      reference: reference,
      title: title,
      chapter: chapter ?? this.chapter,
      coverUrl: coverUrl,
      preferredSource: preferredSource ?? this.preferredSource,
    );
  }
}
