import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/downloads/download_starter.dart';
import 'package:kolektaku/platform/stream_resolver.dart';
import 'package:kolektaku/src/rust/dto/downloads.dart';
import 'package:kolektaku/src/rust/dto/stream.dart';

import '../../support/fake_download_gateway.dart';
import 'download_support.dart';

const _source = StreamSourceDto(
  url: 'https://hls.test/master.m3u8',
  kind: 'hls',
  quality: 0,
  label: 'Otomatis',
  isDefault: true,
);

ResolvedStream resolved({List<HeaderDto> own = const []}) => ResolvedStream(
  set: StreamSetDto(
    sources: const [_source],
    headers: own,
    subtitles: const [],
    skips: const [],
  ),
  headers: const {'Referer': 'https://page.test/ep'},
);

void main() {
  test('a stream without its own headers carries the page referer', () {
    final set = streamForDownload(resolved());
    expect(set.headers.single.name, 'Referer');
    expect(set.headers.single.value, 'https://page.test/ep');
    final own = streamForDownload(
      resolved(
        own: const [HeaderDto(name: 'origin', value: 'x')],
      ),
    );
    expect(own.headers.single.name, 'origin');
  });

  test('a batch queues every episode it can find and lists the rest', () async {
    final gateway = FakeDownloadGateway();
    final steps = <int>[];
    final starter = DownloadStarter(
      gateway: gateway,
      load: (target, preferred) async {
        if (target.episode == 2) throw StateError('missing');
        return resolved();
      },
    );
    final report = await starter.start([
      target(1),
      target(2),
      target(3),
    ], onStep: (done, total) => steps.add(done));
    expect(report.queued, 2);
    expect(report.failed, [2]);
    expect(gateway.enqueued.map((entry) => entry.$1.episode), [1, 3]);
    expect(steps, [1, 2, 3]);
  });

  test('a retry looks the video up again before asking the core', () async {
    final gateway = FakeDownloadGateway()
      ..jobs = [job(4, DownloadPhaseDto.failed)];
    var looked = 0;
    final starter = DownloadStarter(
      gateway: gateway,
      load: (target, preferred) async {
        looked++;
        return resolved();
      },
    );
    expect(await starter.retry(gateway.jobs.first), isTrue);
    expect(looked, 1);
    expect(gateway.retried, [4]);
  });

  test(
    'an episode already playing is queued without looking it up again',
    () async {
      final gateway = FakeDownloadGateway();
      final starter = DownloadStarter(
        gateway: gateway,
        load: (target, preferred) => throw StateError('should not look up'),
      );
      expect(await starter.enqueueResolved(target(7), resolved()), isTrue);
      gateway.failure = StateError('refused');
      expect(await starter.enqueueResolved(target(8), resolved()), isFalse);
    },
  );
}
