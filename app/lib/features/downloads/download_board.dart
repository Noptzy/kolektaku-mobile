import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gateways/download_gateway.dart';
import '../../data/providers/download_providers.dart';
import '../../platform/download_device.dart';
import '../../src/rust/dto/downloads.dart';
import 'download_logic.dart';

const downloadPollEvery = Duration(milliseconds: 700);

class DownloadBoard extends Notifier<List<DownloadDto>> {
  late DownloadGateway gateway;
  late DownloadDevice device;

  Timer? _timer;
  bool _wasActive = false;
  final Set<int> _exporting = {};
  Future<void>? _ready;

  Future<void> get ready => _ready ??= _useFolder();

  @override
  List<DownloadDto> build() {
    gateway = ref.read(downloadGatewayProvider);
    device = ref.read(downloadDeviceProvider);
    ref.onDispose(() => _timer?.cancel());
    Future.microtask(refresh);
    return const [];
  }

  Future<void> _useFolder() async {
    final folder = await device.folder();
    if (folder == null) return;
    try {
      await gateway.useFolder(folder);
    } on Object {
      _ready = null;
    }
  }

  Future<void> refresh() async {
    _timer?.cancel();
    await ready;
    final List<DownloadDto> jobs;
    try {
      jobs = await gateway.list();
    } on Object {
      return;
    }
    if (!ref.mounted) return;
    state = jobs;
    final active = activeOf(jobs).isNotEmpty;
    unawaited(_keepAlive(jobs, active));
    for (final job in jobs.where(needsExport)) {
      unawaited(_export(job));
    }
    _schedule(active);
  }

  void _schedule(bool active) {
    if (!active || !ref.mounted) return;
    _timer = Timer(downloadPollEvery, refresh);
  }

  Future<void> _keepAlive(List<DownloadDto> jobs, bool active) async {
    if (!active && !_wasActive) return;
    _wasActive = active;
    final progress = overallProgress(jobs);
    await device.keepAlive(
      active: active,
      title: active ? notificationTitle(jobs) : '',
      text: notificationText(jobs),
      progress: progress == null ? -1 : (progress * 100).round(),
    );
  }

  Future<void> _export(DownloadDto job) async {
    if (!_exporting.add(job.id)) return;
    try {
      final moved = await device.publish(job.filePath!);
      if (moved != null) await gateway.relocate(job.id, moved);
    } on Object {
      return;
    }
    if (ref.mounted) unawaited(refresh());
  }

  Future<void> cancel(DownloadDto job) async {
    await gateway.cancel(job.id);
    await refresh();
  }

  Future<void> remove(DownloadDto job, {required bool deleteFile}) async {
    final path = job.filePath;
    final shared = path != null && path.startsWith('content://');
    if (deleteFile && shared) await device.delete(path);
    await gateway.remove(job.id, deleteFile: deleteFile && !shared);
    await refresh();
  }

  Future<bool> open(DownloadDto job) {
    final path = job.filePath;
    if (path == null) return Future.value(false);
    return device.open(path, fileNameOf(job));
  }
}
