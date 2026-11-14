import '../src/rust/api/play.dart' as core;
import '../src/rust/dto/stream.dart';
import 'webview_stream_runner.dart';

class ResolvedStream {
  const ResolvedStream({required this.set, required this.headers});

  final StreamSetDto set;
  final Map<String, String> headers;

  ResolvedStream withFirst(StreamSourceDto first) => ResolvedStream(
    set: StreamSetDto(
      sources: [first, ...set.sources.where((source) => source != first)],
      posterUrl: set.posterUrl,
      headers: set.headers,
      subtitles: set.subtitles,
      skips: set.skips,
    ),
    headers: headers,
  );
}

Map<String, String> requestHeaders(StreamSetDto set, String pageUrl) {
  final own = {for (final header in set.headers) header.name: header.value};
  return own.isEmpty ? {'Referer': pageUrl} : own;
}

class StreamResolver {
  const StreamResolver({this.runner = const WebViewStreamRunner()});

  final WebViewStreamRunner runner;

  Future<ResolvedStream> resolve({
    required String source,
    required String episodeId,
    required String server,
  }) async {
    final plan = await core.streamPlan(
      source: source,
      episodeId: episodeId,
      server: server,
    );
    return switch (plan.kind) {
      StreamPlanKind.direct => ResolvedStream(
        set: StreamSetDto(
          sources: plan.sources,
          headers: const [],
          subtitles: const [],
          skips: const [],
        ),
        headers: {for (final header in plan.headers) header.name: header.value},
      ),
      StreamPlanKind.needsWebView => await _viaWebView(source, plan),
    };
  }

  Future<ResolvedStream> _viaWebView(String source, StreamPlanDto plan) async {
    final payload = await runner.collectPayload(plan);
    final set = await core.parseStreamPayload(source: source, payload: payload);
    return ResolvedStream(set: set, headers: requestHeaders(set, plan.url));
  }
}
