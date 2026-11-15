import '../../../src/rust/api/subtitle.dart' as core;
import '../../../src/rust/dto/cues.dart';
import '../../../src/rust/dto/stream.dart';

class CueRequest {
  const CueRequest({
    required this.url,
    required this.headers,
    required this.language,
    required this.positionMs,
    required this.translate,
  });

  final String url;
  final List<HeaderDto> headers;
  final String? language;
  final int positionMs;
  final bool translate;
}

typedef CueLoader = Future<CuePlanDto> Function(CueRequest request);

Future<CuePlanDto> loadCuesFromCore(CueRequest request) => core.fetchCues(
  url: request.url,
  headers: request.headers,
  language: request.language,
  positionMs: BigInt.from(request.positionMs),
  translate: request.translate,
);
