import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

void announceSourceSwitch(BuildContext context, String? switchedFrom) {
  if (switchedFrom == null) return;
  ShadToaster.of(context)
      .show(const ShadToast(description: Text('Dibaca dari sumber lain.')));
}
