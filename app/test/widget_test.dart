import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/app.dart';
import 'package:kolektaku/app_scope.dart';
import 'package:kolektaku/data/providers/gateway_providers.dart';

import 'support/fake_catalog_gateway.dart';
import 'support/fake_library_gateway.dart';
import 'support/fake_settings_gateway.dart';
import 'support/fake_translation_gateway.dart';
import 'support/fake_source_gateway.dart';

void main() {
  testWidgets('the app opens on the shell with its four destinations', (
    tester,
  ) async {
    await tester.pumpWidget(
      kolektakuScope(
        overrides: [
          catalogGatewayProvider.overrideWithValue(FakeCatalogGateway()),
          libraryGatewayProvider.overrideWithValue(FakeLibraryGateway()),
          sourceGatewayProvider.overrideWithValue(FakeSourceGateway()),
          settingsGatewayProvider.overrideWithValue(FakeSettingsGateway()),
          translationGatewayProvider.overrideWithValue(
            FakeTranslationGateway(),
          ),
        ],
        child: const KolektakuApp(),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['Beranda', 'Cari', 'Koleksi', 'Pengaturan']) {
      expect(find.text(label), findsWidgets, reason: label);
    }
  });
}
