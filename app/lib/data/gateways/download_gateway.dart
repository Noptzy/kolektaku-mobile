import '../../src/rust/api/downloads.dart' as core;
import '../../src/rust/dto/downloads.dart';
import '../../src/rust/dto/stream.dart';

abstract interface class DownloadGateway {
  Future<List<DownloadDto>> list();

  Future<DownloadDto> enqueue(DownloadTargetDto target, StreamSetDto stream);

  Future<DownloadDto?> retry(int id, StreamSetDto stream);

  Future<void> cancel(int id);

  Future<void> remove(int id, {required bool deleteFile});

  Future<void> relocate(int id, String path);

  Future<DownloadSettingsDto> settings();

  Future<DownloadSettingsDto> saveSettings(DownloadSettingsDto settings);

  Future<void> useFolder(String folder);
}

class BridgeDownloadGateway implements DownloadGateway {
  const BridgeDownloadGateway();

  @override
  Future<List<DownloadDto>> list() => core.downloadsList();

  @override
  Future<DownloadDto> enqueue(DownloadTargetDto target, StreamSetDto stream) =>
      core.downloadsEnqueue(target: target, stream: stream);

  @override
  Future<DownloadDto?> retry(int id, StreamSetDto stream) =>
      core.downloadsRetry(id: id, stream: stream);

  @override
  Future<void> cancel(int id) => core.downloadsCancel(id: id);

  @override
  Future<void> remove(int id, {required bool deleteFile}) =>
      core.downloadsRemove(id: id, deleteFile: deleteFile);

  @override
  Future<void> relocate(int id, String path) =>
      core.downloadsRelocate(id: id, path: path);

  @override
  Future<DownloadSettingsDto> settings() => core.downloadsSettings();

  @override
  Future<DownloadSettingsDto> saveSettings(DownloadSettingsDto settings) =>
      core.downloadsSaveSettings(settings: settings);

  @override
  Future<void> useFolder(String folder) =>
      core.downloadsUseFolder(folder: folder);
}
