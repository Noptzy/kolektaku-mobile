import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/app.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/core/router.dart';
import 'package:kolektaku/core/routes.dart';
import 'package:kolektaku/data/core_session.dart';
import 'package:kolektaku/features/detail/detail_request.dart';
import 'package:kolektaku/platform/picture_source.dart';
import 'package:kolektaku/src/rust/dto/media.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';
import 'package:kolektaku/widgets/genre_card.dart';
import 'package:kolektaku/widgets/media_card.dart';

import 'package:kolektaku/features/scene_search/scene_candidate_row.dart';

import 'support/pipeline_steps.dart';
import 'support/sample_pictures.dart';
import 'support/tour_helpers.dart';
import 'support/watch_driver.dart';

const hold = int.fromEnvironment('HOLD', defaultValue: 6);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await RustLib.init();
    await startCore();
  });

  testWidgets('tour of every screen that exists', (tester) async {
    final picture = await download(sample);
    await tester.pumpWidget(
      kolektakuScope(
        overrides: [
          pictureSourceProvider.overrideWithValue(SamplePictures(picture)),
        ],
        child: const KolektakuApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    Future<void> shot(String name) async {
      debugPrint('TOUR:$name');
      await tester.pump(const Duration(seconds: hold));
    }

    Future<bool> until(bool Function() ready, {int seconds = 90}) =>
        waitFor(tester, ready, timeout: Duration(seconds: seconds));

    bool shown(String text) => find.text(text).evaluate().isNotEmpty;

    Future<void> step(String name, Future<void> Function() body) async {
      try {
        await body();
      } on Object catch (error) {
        debugPrint('TOURFAIL:$name:${error.toString().split('\n').first}');
      }
    }

    Future<void> drag(double dy) async {
      await tester.drag(find.byType(Scrollable).first, Offset(0, dy));
      await tester.pump(const Duration(milliseconds: 800));
    }

    Future<void> back() async {
      if (kolektakuRouter.canPop()) kolektakuRouter.pop();
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> closeSheet() async {
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> tab(String label) => openBottomTab(tester, label);

    await step('home_anime', () async {
      kolektakuRouter.go(Routes.home);
      await until(() => shown('Top 10 anime'));
      await shot('01_beranda_anime');
      await drag(-1500);
      await shot('02_beranda_anime_tengah');
      await drag(-1500);
      await shot('03_beranda_anime_bawah');
    });

    await step('home_manga_rails', () async {
      await drag(-1500);
      await until(() => shown('Top 10 manga'));
      await shot('04_beranda_manga');
    });

    await step('koleksiku', () async {
      await tab('Koleksi');
      await shot('05_koleksiku');
      await tab('Beranda');
    });

    await step('search', () async {
      kolektakuRouter.go(Routes.search);
      await tester.pump(const Duration(seconds: 2));
      await shot('06_cari_kosong');
      await tester.enterText(find.byType(EditableText), 'kimi no nawa');
      await until(() => shown('Kimi no Na wa.'));
      await tester.pump(const Duration(seconds: 2));
      await shot('07_cari_hasil');
      await back();
    });

    await step('genres', () async {
      kolektakuRouter.push(Routes.genres, extra: MediaKindDto.anime);
      await until(() => find.byType(GenreCard).evaluate().isNotEmpty);
      await shot('08_genre');
      await tester.tap(find.byType(GenreCard).first);
      await until(() => find.byType(MediaCard).evaluate().isNotEmpty);
      await tester.pump(const Duration(seconds: 3));
      await shot('09_genre_daftar');
      await back();
      await back();
    });

    await step('detail_film', () async {
      kolektakuRouter.push(
        Routes.detail,
        extra: DetailRequest(
          kind: MediaKindDto.anime,
          reference: catalogRef(21519),
        ),
      );
      await until(() => shown('Tonton film'));
      await tester.pump(const Duration(seconds: 3));
      await shot('10_detail_anime_atas');
      await drag(-900);
      await shot('11_detail_anime_bawah');
      for (final entry in {
        'Karakter': '12_detail_tab_karakter',
        'Info': '13_detail_tab_info',
        'Terkait': '14_detail_tab_terkait',
      }.entries) {
        await tester.ensureVisible(find.text(entry.key).first);
        await tester.tap(find.text(entry.key).first);
        await tester.pump(const Duration(seconds: 1));
        await drag(-700);
        await shot(entry.value);
        await drag(2500);
      }
      await tester.ensureVisible(find.textContaining('Sumber:'));
      await tester.tap(find.textContaining('Sumber:'));
      await tester.pump(const Duration(seconds: 2));
      await shot('15_detail_pilih_sumber');
      await closeSheet();
      await tester.tap(find.text('Bukan ini?'));
      await tester.pump(const Duration(seconds: 4));
      await shot('16_detail_bukan_ini');
      await closeSheet();
      await back();
    });

    await step('detail_series', () async {
      kolektakuRouter.push(
        Routes.detail,
        extra: DetailRequest(
          kind: MediaKindDto.anime,
          reference: catalogRef(101922),
        ),
      );
      await until(() => shown('Tonton Episode 1'));
      await tester.pump(const Duration(seconds: 3));
      await shot('17_detail_serial_atas');
      await drag(-1100);
      await shot('18_detail_serial_episode');
      await drag(1500);
      await tester.tap(find.text('Tonton Episode 1'));
      final playing = await until(
        () => (shownPosition(tester) ?? Duration.zero) > Duration.zero,
        seconds: 150,
      );
      if (playing) await tester.pump(const Duration(seconds: 3));
      await shot('19_nonton');
      await drag(-700);
      await shot('20_nonton_daftar_episode');
      await back();
      await back();
    });

    await step('scene', () async {
      kolektakuRouter.push(Routes.sceneSearch);
      await tester.pump(const Duration(seconds: 2));
      await shot('21_cari_gambar');
      await tester.tap(find.text('Pilih dari berkas'));
      await until(() => shown('Mungkin ini adegannya'));
      await tester.pump(const Duration(seconds: 3));
      await shot('22_cari_gambar_hasil');
      await tester.tap(find.byType(SceneCandidateRow).first);
      final playing = await until(
        () => (shownPosition(tester) ?? Duration.zero) > Duration.zero,
        seconds: 150,
      );
      if (playing) await tester.pump(const Duration(seconds: 3));
      await shot('23_cari_gambar_nonton');
      await back();
      await back();
    });

    await step('gallery', () async {
      kolektakuRouter.push(Routes.gallery);
      await tester.pump(const Duration(seconds: 2));
      await shot('25_galeri_komponen');
      await drag(-1800);
      await shot('26_galeri_komponen_bawah');
    });

    debugPrint('TOUR:done');
  }, timeout: const Timeout(Duration(minutes: 25)));
}
