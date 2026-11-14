import '../../../features/watch/player/playback_engine.dart';
import '../../../features/watch/player/video_player_engine.dart';
import '../../../platform/stream_resolver.dart';
import '../../../src/rust/api/browse.dart' as browse;
import '../../../src/rust/api/detail.dart' as detail;
import '../../../src/rust/api/play.dart' as play;
import '../../../src/rust/api/sources.dart' as sources;
import '../../../src/rust/dto/media.dart';
import '../../../src/rust/dto/stream.dart';
import 'gate_runner.dart';

const _kimiNoNaWa = 21519;

MediaRefDto _film() => MediaRefDto(
  kind: MediaRefKind.catalog,
  id: BigInt.from(_kimiNoNaWa),
  source: '',
  item: '',
);

Future<String> _sources() async {
  final all = await sources.sourcesStatus();
  return all.map((status) => status.id).join(', ');
}

Future<String> _home() async {
  final home = await browse.home(kind: MediaKindDto.anime);
  final empty = home.sections.where((section) => section.cards.isEmpty);
  if (empty.isNotEmpty) throw StateError('empty: ${empty.first.id}');
  return home.sections.map((section) => section.id).join(', ');
}

Future<String> _search() async {
  final page = await browse.search(
    kind: MediaKindDto.anime,
    query: 'kimi no nawa',
    page: 1,
  );
  final film = page.cards.firstWhere((card) => card.title == 'Kimi no Na wa.');
  return film.sources.join(', ');
}

Future<String> _detail() async {
  final view = await detail.mediaDetail(
    kind: MediaKindDto.anime,
    reference: _film(),
  );
  final links = view.catalog!.sources;
  if (links.isEmpty) throw StateError('no source linked');
  return 'sumber ${links.first.source}';
}

Future<PlaybackDto> _episode() =>
    play.openEpisode(reference: _film(), episode: 1, exclude: const []);

Future<ResolvedStream> _stream() async {
  final playback = await _episode();
  return const StreamResolver().resolve(
    source: playback.source,
    episodeId: playback.unit.id,
    server: playback.servers.first.id,
  );
}

Future<String> _servers() async {
  final playback = await _episode();
  return playback.servers.map((server) => server.id).join(', ');
}

Future<String> _resolved() async {
  final stream = await _stream();
  return stream.set.sources.map((source) => source.label).join(', ');
}

Future<String> _played() async {
  final stream = await _stream();
  final engine = VideoPlayerEngine();
  try {
    final first = stream.set.sources.first;
    await engine.open(PlayableSource(url: first.url, headers: stream.headers));
    await Future<void>.delayed(const Duration(seconds: 6));
    final snapshot = engine.snapshot.value;
    if (snapshot.failure != null) throw StateError(snapshot.failure!);
    if (snapshot.position < const Duration(seconds: 3)) {
      throw StateError('stuck at ${snapshot.position}');
    }
    return 'posisi ${snapshot.position.inSeconds} dtk';
  } finally {
    await engine.dispose();
  }
}

Future<String> _manga() async {
  final page = await browse.search(
    kind: MediaKindDto.manga,
    query: 'chainsaw man',
    page: 1,
  );
  final card = page.cards.firstWhere(
    (card) => card.title.toLowerCase().contains('chainsaw man'),
  );
  await detail.mediaDetail(kind: MediaKindDto.manga, reference: card.reference);
  final view = await play.openChapter(
    reference: card.reference,
    chapter: 1,
    exclude: const [],
  );
  if (view.pages.length < 3) {
    throw StateError('only ${view.pages.length} pages');
  }
  return '${view.pages.length} halaman dari ${view.source}';
}

List<GateStep> coreGateSteps() => [
  GateStep('sumber terdaftar', _sources),
  GateStep('beranda anime', _home),
  GateStep('cari salah ketik', _search),
  GateStep('detail dan sumber', _detail),
  GateStep('server episode', _servers),
  GateStep('rencana stream lewat WebView', _resolved),
  GateStep('memutar 6 detik', _played),
  GateStep('manga: gambar chapter', _manga),
];
