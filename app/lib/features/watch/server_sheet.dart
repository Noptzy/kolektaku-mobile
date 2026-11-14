import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../src/rust/dto/stream.dart';
import '../../widgets/sheet_scroll.dart';
import '../../widgets/swipe_sheet.dart';
import 'server_choice.dart';
import 'server_options.dart';

Future<ServerChoice?> showServerSheet(
  BuildContext context, {
  required List<ServerDto> servers,
  required String? current,
  List<OtherSource> others = const [],
}) {
  return showSwipeSheet<ServerChoice>(
    context: context,
    builder: (sheetContext) => ShadSheet(
      title: const Text('Ganti server'),
      description: Text(serverHint(servers)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.md),
        child: SheetScroll(
          child: ServerOptions(
            servers: servers,
            current: current,
            others: others,
            onChoice: (choice) => Navigator.of(sheetContext).pop(choice),
          ),
        ),
      ),
    ),
  );
}
