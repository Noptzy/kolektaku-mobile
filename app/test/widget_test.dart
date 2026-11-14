import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/app.dart';

void main() {
  testWidgets('menampilkan pratinjau tema dengan tombol tonton', (
    tester,
  ) async {
    await tester.pumpWidget(const KolektakuApp());
    await tester.pumpAndSettle();

    expect(find.text('Pratinjau tema Kolektaku'), findsOneWidget);
    expect(find.text('Tonton sekarang'), findsOneWidget);
    expect(find.text('Anime'), findsOneWidget);
    expect(find.text('Manga'), findsOneWidget);
  });
}
