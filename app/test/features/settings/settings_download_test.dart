import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/settings/download_section.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/src/rust/dto/downloads.dart';
import 'package:kolektaku/widgets/option_chip.dart';

import '../../support/screen_harness.dart';

Future<ScreenHarness> open(WidgetTester tester) async {
  final harness = ScreenHarness();
  await harness.pump(
    tester,
    const SettingsPageScreen(page: SettingsPage.downloads),
    size: const Size(390, 1400),
  );
  return harness;
}

void main() {
  test('the summary names the quality and the subtitle choice', () {
    expect(downloadSummary(null), 'MKV dengan subtitle');
    expect(
      downloadSummary(
        const DownloadSettingsDto(
          subtitles: DownloadSubtitlesDto.translated,
          quality: '1080',
        ),
      ),
      '1080p · subtitle terjemahan',
    );
    expect(
      downloadSummary(
        const DownloadSettingsDto(
          subtitles: DownloadSubtitlesDto.off,
          quality: 'odd',
        ),
      ),
      '720p · tanpa subtitle',
    );
  });

  testWidgets('choosing subtitles and quality saves both', (tester) async {
    final harness = await open(tester);
    await tester.tap(find.widgetWithText(OptionChip, 'Teks asli saja'));
    await tester.pumpAndSettle();
    expect(harness.downloads.saved.subtitles, DownloadSubtitlesDto.original);
    await tester.tap(find.widgetWithText(OptionChip, '480p'));
    await tester.pumpAndSettle();
    expect(harness.downloads.saved.quality, '480');
    expect(harness.downloads.saved.subtitles, DownloadSubtitlesDto.original);
  });

  testWidgets('the page leads to the list of downloads', (tester) async {
    final harness = await open(tester);
    await tester.ensureVisible(find.byKey(const Key('open-downloads')));
    await tester.tap(find.byKey(const Key('open-downloads')));
    await tester.pumpAndSettle();
    expect(harness.visits.last.path, '/unduhan');
  });
}
