import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kolektaku/app.dart';
import 'package:kolektaku/src/rust/frb_generated.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => RustLib.init());

  testWidgets('menampilkan pratinjau tema di perangkat', (tester) async {
    await tester.pumpWidget(const KolektakuApp());
    await tester.pumpAndSettle();

    expect(find.text('Pratinjau tema Kolektaku'), findsOneWidget);
    expect(find.text('Tonton sekarang'), findsOneWidget);
  });
}
