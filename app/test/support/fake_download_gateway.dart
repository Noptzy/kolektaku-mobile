import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kolektaku/data/gateways/download_gateway.dart';
import 'package:kolektaku/data/providers/download_providers.dart';
import 'package:kolektaku/platform/download_device.dart';
import 'package:kolektaku/src/rust/dto/downloads.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';

class FakeDownloadGateway implements DownloadGateway {
  List<DownloadDto> jobs = [];
  final List<(DownloadTargetDto, StreamSetDto)> enqueued = [];
  final List<int> cancelled = [];
  final List<(int, bool)> removed = [];
  final List<(int, String)> relocated = [];
  final List<int> retried = [];
  String? folder;
  DownloadSettingsDto saved = const DownloadSettingsDto(
    subtitles: DownloadSubtitlesDto.translated,
    quality: '720',
  );
  Object? failure;

  @override
  Future<List<DownloadDto>> list() async => List.of(jobs);

  @override
  Future<DownloadDto> enqueue(
    DownloadTargetDto target,
    StreamSetDto stream,
  ) async {
    final error = failure;
    if (error != null) throw error;
    enqueued.add((target, stream));
    final job = DownloadDto(
      id: enqueued.length,
      target: target,
      phase: DownloadPhaseDto.queued,
      progress: 0,
      bytes: BigInt.zero,
      interrupted: false,
    );
    jobs = [job, ...jobs];
    return job;
  }

  @override
  Future<DownloadDto?> retry(int id, StreamSetDto stream) async {
    retried.add(id);
    return jobs.where((job) => job.id == id).firstOrNull;
  }

  @override
  Future<void> cancel(int id) async => cancelled.add(id);

  @override
  Future<void> remove(int id, {required bool deleteFile}) async {
    removed.add((id, deleteFile));
    jobs = [
      for (final job in jobs)
        if (job.id != id) job,
    ];
  }

  @override
  Future<void> relocate(int id, String path) async => relocated.add((id, path));

  @override
  Future<DownloadSettingsDto> settings() async => saved;

  @override
  Future<DownloadSettingsDto> saveSettings(
    DownloadSettingsDto settings,
  ) async => saved = settings;

  @override
  Future<void> useFolder(String folder) async => this.folder = folder;
}

class FakeDownloadDevice implements DownloadDevice {
  final List<(bool, String, int)> alive = [];
  final List<String> published = [];
  final List<String> deleted = [];
  final List<String> opened = [];
  String? publishAs;

  @override
  Future<void> keepAlive({
    required bool active,
    String title = '',
    String text = '',
    int progress = -1,
  }) async => alive.add((active, title, progress));

  @override
  Future<String?> publish(String path) async {
    published.add(path);
    return publishAs;
  }

  @override
  Future<bool> delete(String target) async {
    deleted.add(target);
    return true;
  }

  @override
  Future<bool> open(String target, String name) async {
    opened.add(target);
    return true;
  }

  @override
  Future<String?> folder() async => '/storage/films';
}

Widget withDownloadFakes(Widget child, FakeDownloadGateway gateway) {
  return ProviderScope(
    overrides: [
      downloadGatewayProvider.overrideWithValue(gateway),
      downloadDeviceProvider.overrideWithValue(FakeDownloadDevice()),
    ],
    child: child,
  );
}
