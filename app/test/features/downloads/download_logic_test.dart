import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/downloads/download_launch.dart';
import 'package:kolektaku/features/downloads/download_logic.dart';
import 'package:kolektaku/features/downloads/download_starter.dart';
import 'package:kolektaku/src/rust/dto/downloads.dart';

import 'download_support.dart';

void main() {
  test('only waiting and working downloads count as active', () {
    final jobs = [
      job(1, DownloadPhaseDto.fetching, progress: 0.5),
      job(2, DownloadPhaseDto.queued),
      job(3, DownloadPhaseDto.done, progress: 1),
    ];
    expect(activeOf(jobs).map((job) => job.id), [1, 2]);
    expect(overallProgress(jobs), 0.25);
    expect(overallProgress([job(3, DownloadPhaseDto.done)]), isNull);
  });

  test('each phase reads as plain indonesian', () {
    expect(
      phaseLabel(job(1, DownloadPhaseDto.fetching, progress: 0.42)),
      'Mengunduh 42%',
    );
    expect(phaseLabel(job(1, DownloadPhaseDto.queued)), 'Menunggu giliran');
    expect(
      phaseLabel(job(1, DownloadPhaseDto.failed, interrupted: true)),
      'Terhenti saat aplikasi ditutup',
    );
    expect(phaseLabel(job(1, DownloadPhaseDto.failed)), 'Gagal mengunduh');
  });

  test('sizes grow from kilobytes to gigabytes', () {
    expect(sizeLabel(BigInt.from(2048)), '2 KB');
    expect(sizeLabel(BigInt.from(5 * 1024 * 1024 + 300000)), '5,3 MB');
    expect(
      sizeLabel(BigInt.from(3) * BigInt.from(1024 * 1024 * 1024)),
      '3,00 GB',
    );
  });

  test('only a finished file still in the app folder is moved to movies', () {
    expect(
      needsExport(job(1, DownloadPhaseDto.done, filePath: '/a/b.mkv')),
      isTrue,
    );
    expect(
      needsExport(job(1, DownloadPhaseDto.done, filePath: 'content://m/1')),
      isFalse,
    );
    expect(
      needsExport(job(1, DownloadPhaseDto.fetching, filePath: '/a/b.mkv')),
      isFalse,
    );
  });

  test('the notification names one title or counts several', () {
    final one = [job(1, DownloadPhaseDto.fetching, progress: 0.5)];
    expect(notificationTitle(one), 'Judul · Episode 1');
    expect(notificationText(one), 'Mengunduh 50% · total 50%');
    final two = [...one, job(2, DownloadPhaseDto.queued, episode: 2)];
    expect(notificationTitle(two), 'Mengunduh 2 episode');
  });

  test('episodes already saved or on the way are marked', () {
    final jobs = [
      job(1, DownloadPhaseDto.done, episode: 1),
      job(2, DownloadPhaseDto.failed, episode: 2),
      job(3, DownloadPhaseDto.queued, episode: 3),
    ];
    expect(savedEpisodes(jobs, catalogRef(1)), {1.0, 3.0});
    expect(savedEpisodes(jobs, catalogRef(9)), isEmpty);
  });

  test('the start message names the episodes that could not be found', () {
    expect(
      startedMessage(const StartReport(queued: 3, failed: [])),
      '3 episode masuk antrean unduhan.',
    );
    expect(
      startedMessage(const StartReport(queued: 1, failed: [2, 5])),
      '1 episode masuk antrean unduhan. Episode 2, 5 belum bisa ditemukan.',
    );
    expect(
      startedMessage(const StartReport(queued: 0, failed: [1])),
      contains('belum bisa'),
    );
  });
}
