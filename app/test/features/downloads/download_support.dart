import 'package:kolektaku/src/rust/dto/downloads.dart';
import 'package:kolektaku/src/rust/dto/media.dart';

MediaRefDto catalogRef(int id) => MediaRefDto(
  kind: MediaRefKind.catalog,
  id: BigInt.from(id),
  source: '',
  item: '',
);

DownloadTargetDto target(
  double episode, {
  int id = 1,
  String title = 'Judul',
}) => DownloadTargetDto(
  reference: catalogRef(id),
  kind: MediaKindDto.anime,
  title: title,
  episode: episode,
);

DownloadDto job(
  int id,
  DownloadPhaseDto phase, {
  double progress = 0,
  double episode = 1,
  String? filePath,
  bool interrupted = false,
  int bytes = 0,
}) => DownloadDto(
  id: id,
  target: target(episode),
  phase: phase,
  progress: progress,
  bytes: BigInt.from(bytes),
  filePath: filePath,
  interrupted: interrupted,
);
