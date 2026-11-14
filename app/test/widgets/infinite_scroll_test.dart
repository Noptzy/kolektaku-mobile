import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolektaku/widgets/infinite_scroll.dart';

Widget host({
  required bool enabled,
  required VoidCallback onMore,
  required int rows,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: 300,
      height: 400,
      child: InfiniteScroll(
        enabled: enabled,
        onMore: onMore,
        builder: (context, controller) => ListView(
          controller: controller,
          children: [
            for (var i = 0; i < rows; i++)
              SizedBox(height: 100, key: ValueKey(i)),
          ],
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('a list shorter than the screen asks for more at once', (
    tester,
  ) async {
    var asked = 0;
    await tester.pumpWidget(
      host(enabled: true, rows: 2, onMore: () => asked++),
    );
    await tester.pump();
    expect(asked, greaterThan(0));
  });

  testWidgets('a long list stays quiet until the end is near', (tester) async {
    var asked = 0;
    await tester.pumpWidget(
      host(enabled: true, rows: 30, onMore: () => asked++),
    );
    await tester.pump();
    expect(asked, 0);
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pump();
    expect(asked, 0);
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pump();
    expect(asked, greaterThan(0));
  });

  testWidgets('when disabled it never asks', (tester) async {
    var asked = 0;
    await tester.pumpWidget(
      host(enabled: false, rows: 2, onMore: () => asked++),
    );
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    expect(asked, 0);
  });

  testWidgets('enabling it later asks right away if the end is close', (
    tester,
  ) async {
    var asked = 0;
    await tester.pumpWidget(
      host(enabled: false, rows: 3, onMore: () => asked++),
    );
    await tester.pump();
    expect(asked, 0);
    await tester.pumpWidget(
      host(enabled: true, rows: 3, onMore: () => asked++),
    );
    await tester.pump();
    expect(asked, greaterThan(0));
  });

  testWidgets('it hands its controller to the list', (tester) async {
    ScrollController? seen;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: InfiniteScroll(
          enabled: false,
          onMore: () {},
          builder: (context, controller) {
            seen = controller;
            return ListView(controller: controller);
          },
        ),
      ),
    );
    expect(seen, isNotNull);
  });
}
