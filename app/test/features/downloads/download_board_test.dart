import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/data/providers/download_providers.dart';
import 'package:kolektaku/src/rust/dto/downloads.dart';

import '../../support/fake_download_gateway.dart';
import 'download_support.dart';

ProviderContainer board(
  FakeDownloadGateway gateway,
  FakeDownloadDevice device,
) {
  final container = ProviderContainer(
    overrides: [
      downloadGatewayProvider.overrideWithValue(gateway),
      downloadDeviceProvider.overrideWithValue(device),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'the board tells the core where to save and shows its downloads',
    () async {
      final gateway = FakeDownloadGateway()
        ..jobs = [job(1, DownloadPhaseDto.done)];
      final container = board(gateway, FakeDownloadDevice());
      container.read(downloadsProvider);
      await container.read(downloadsProvider.notifier).refresh();
      expect(gateway.folder, '/storage/films');
      expect(container.read(downloadsProvider).single.id, 1);
    },
  );

  test(
    'while downloading the phone keeps the app alive and lets go after',
    () async {
      final gateway = FakeDownloadGateway()
        ..jobs = [job(1, DownloadPhaseDto.fetching, progress: 0.3)];
      final device = FakeDownloadDevice();
      final container = board(gateway, device);
      final notifier = container.read(downloadsProvider.notifier);
      await notifier.refresh();
      expect(device.alive.last, (true, 'Judul · Episode 1', 30));
      gateway.jobs = [job(1, DownloadPhaseDto.done, progress: 1)];
      await notifier.refresh();
      expect(device.alive.last.$1, isFalse);
    },
  );

  test(
    'a finished file is moved to movies and its new place remembered',
    () async {
      final gateway = FakeDownloadGateway()
        ..jobs = [
          job(1, DownloadPhaseDto.done, filePath: '/app/Unduhan/a.mkv'),
        ];
      final device = FakeDownloadDevice()..publishAs = 'content://media/1';
      final container = board(gateway, device);
      await container.read(downloadsProvider.notifier).refresh();
      await pumpEventQueue();
      expect(device.published, ['/app/Unduhan/a.mkv']);
      expect(gateway.relocated, [(1, 'content://media/1')]);
    },
  );

  test(
    'removing a shared file deletes it through the phone, not the core',
    () async {
      final done = job(1, DownloadPhaseDto.done, filePath: 'content://media/1');
      final gateway = FakeDownloadGateway()..jobs = [done];
      final device = FakeDownloadDevice();
      final container = board(gateway, device);
      await container
          .read(downloadsProvider.notifier)
          .remove(done, deleteFile: true);
      expect(device.deleted, ['content://media/1']);
      expect(gateway.removed, [(1, false)]);
    },
  );
}
