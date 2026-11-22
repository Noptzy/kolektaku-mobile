import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/features/watch/watch_resume_sheet.dart';

import '../../widgets/widget_harness.dart';

const _sizes = {'390x844': phoneLarge, '360x780': phoneSmall};

void main() {
  _sizes.forEach((label, size) {
    testWidgets('resume sheet at $label', (tester) async {
      await pumpAtSize(
        tester,
        Builder(
          builder: (context) => GestureDetector(
            key: const Key('open'),
            behavior: HitTestBehavior.opaque,
            onTap: () => showResumeSheet(
              context,
              position: const Duration(minutes: 12, seconds: 30),
              length: const Duration(minutes: 24, seconds: 10),
              info: const ResumeSheetInfo(
                title: 'Sousou no Frieren: Perjalanan Setelah Kemenangan',
                coverUrl: null,
                episode: 4,
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        size: size,
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(Navigator).first,
        matchesGoldenFile('goldens/resume_sheet_$label.png'),
      );
    });
  });
}
