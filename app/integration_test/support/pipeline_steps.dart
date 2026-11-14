import 'dart:io';

import 'package:flutter/services.dart' show PlatformException;
import 'package:kolektaku/platform/stream_resolver.dart';
import 'package:kolektaku/src/rust/api/browse.dart' as browse;
import 'package:kolektaku/src/rust/api/detail.dart' as detail;
import 'package:kolektaku/src/rust/api/play.dart' as play;
import 'package:kolektaku/src/rust/dto/cards.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/error.dart';
import 'package:video_player/video_player.dart';

MediaRefDto catalogRef(int id) => MediaRefDto(
  kind: MediaRefKind.catalog,
  id: BigInt.from(id),
  source: '',
  item: '',
);

Future<CardPageDto> search(MediaKindDto kind, String query) =>
    browse.search(kind: kind, query: query, page: 1);

MediaCardDto cardTitled(CardPageDto page, String title) =>
    page.cards.firstWhere((card) => card.title == title);

Future<int> unitCountOf(MediaRefDto reference) async {
  final view = await detail.units(reference: reference);
  return view.units.length;
}

Future<ResolvedStream> resolveFirstServer(
  MediaRefDto reference,
  double episode,
) async {
  final playback = await play.openEpisode(
    reference: reference,
    episode: episode,
    exclude: const [],
  );
  return const StreamResolver().resolve(
    source: playback.source,
    episodeId: playback.unit.id,
    server: playback.servers.first.id,
  );
}

Future<Duration> playedFor(ResolvedStream stream, Duration watch) async {
  final controller = VideoPlayerController.networkUrl(
    Uri.parse(stream.set.sources.first.url),
    httpHeaders: stream.headers,
  );
  await controller.initialize();
  await controller.play();
  await Future<void>.delayed(watch);
  final position = controller.value.position;
  await controller.dispose();
  return position;
}

Future<Duration> playedWithOneRetry(
  Future<ResolvedStream> Function() resolve,
  Duration watch,
) async {
  try {
    return await playedFor(await resolve(), watch);
  } on PlatformException {
    return playedFor(await resolve(), watch);
  }
}

Future<int> firstImageStatus(String url, String referer) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('Referer', referer);
    final response = await request.close();
    await response.drain<void>();
    return response.statusCode;
  } finally {
    client.close();
  }
}

Future<T> explained<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on BridgeError catch (error) {
    throw StateError('${error.kind.name}: ${error.detail}');
  }
}

Future<void> openDetail(MediaKindDto kind, MediaRefDto reference) async {
  await explained(() => detail.mediaDetail(kind: kind, reference: reference));
}
