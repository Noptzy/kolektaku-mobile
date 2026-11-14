import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/settings/settings_logic.dart';
import 'package:kolektaku/features/settings/settings_page_screen.dart';
import 'package:kolektaku/features/settings/settings_pages.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/dto/sources.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/screen_harness.dart';

SourceStatusDto status(
  String id, {
  MediaKindDto kind = MediaKindDto.anime,
  bool enabled = true,
  bool skipped = false,
  String summary = '',
}) {
  return SourceStatusDto(
    id: id,
    name: 'Rahasia $id',
    kind: kind,
    enabled: enabled,
    skipped: skipped,
    summary: summary,
  );
}

Future<ScreenHarness> open(
  WidgetTester tester,
  List<SourceStatusDto> statuses, {
  String version = '2.0.0-rc1',
  SettingsPage page = SettingsPage.sources,
}) async {
  final harness = ScreenHarness();
  harness.sources.statuses = statuses;
  await harness.pump(
    tester,
    SettingsPageScreen(page: page),
    size: const Size(390, 3200),
    extra: [appVersionProvider.overrideWith((ref) async => version)],
  );
  return harness;
}

void main() {
  testWidgets('the page has its title and explains what it does', (
    tester,
  ) async {
    await open(tester, [status('a')]);
    expect(find.text('Kelola sumber'), findsOneWidget);
    expect(find.text(SettingsPage.sources.intro), findsOneWidget);
  });

  testWidgets('sources are listed by number and never by site name', (
    tester,
  ) async {
    await open(tester, [
      status('a'),
      status('b'),
      status('m', kind: MediaKindDto.manga),
    ]);
    expect(find.text('Sumber anime 1'), findsOneWidget);
    expect(find.text('Sumber anime 2'), findsOneWidget);
    expect(find.text('Sumber manga 1'), findsOneWidget);
    expect(find.textContaining('Rahasia'), findsNothing);
  });

  testWidgets('each source shows whether it is on, off or skipped', (
    tester,
  ) async {
    await open(tester, [
      status('a'),
      status('b', enabled: false),
      status('c', skipped: true),
    ]);
    expect(find.text('Aktif'), findsNWidgets(1));
    expect(find.text('Dimatikan'), findsOneWidget);
    expect(find.textContaining('dilewati'), findsOneWidget);
  });

  testWidgets('the switch turns a source off and the list refreshes', (
    tester,
  ) async {
    final harness = await open(tester, [status('a')]);
    await tester.tap(find.byKey(const Key('source-switch')));
    await tester.pumpAndSettle();
    expect(harness.sources.toggles, ['a|false']);
    expect(find.text('Dimatikan'), findsOneWidget);
    expect(
      tester.widget<ShadSwitch>(find.byKey(const Key('source-switch'))).value,
      isFalse,
    );
  });

  testWidgets('it turns a source back on too', (tester) async {
    final harness = await open(tester, [status('a', enabled: false)]);
    await tester.tap(find.byKey(const Key('source-switch')));
    await tester.pumpAndSettle();
    expect(harness.sources.toggles, ['a|true']);
    expect(find.text('Aktif'), findsOneWidget);
  });

  testWidgets('switching every source of a kind off warns about it', (
    tester,
  ) async {
    await open(tester, [
      status('a', enabled: false),
      status('m', kind: MediaKindDto.manga),
    ]);
    expect(find.byKey(const Key('all-off-anime')), findsOneWidget);
    expect(find.byKey(const Key('all-off-manga')), findsNothing);
    expect(find.textContaining('tidak ada yang bisa ditonton'), findsOneWidget);
  });

  testWidgets('the about part shows the version and the data providers', (
    tester,
  ) async {
    await open(tester, [status('a')], page: SettingsPage.about);
    expect(find.text('Versi 2.0.0-rc1'), findsOneWidget);
    expect(find.textContaining('AniList'), findsOneWidget);
    expect(find.textContaining('trace.moe'), findsOneWidget);
  });

  testWidgets('without any source the page still opens', (tester) async {
    await open(tester, const []);
    expect(find.text('Kelola sumber'), findsOneWidget);
    expect(find.byKey(const Key('source-switch')), findsNothing);
  });

  testWidgets('it is a sub-page, so there is a back button', (tester) async {
    await open(tester, [status('a')]);
    expect(find.byKey(const Key('settings-back')), findsOneWidget);
  });
}
