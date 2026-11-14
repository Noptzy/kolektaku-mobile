import 'package:flutter/widgets.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../update/update_panel.dart';

class UpdatePanelSection extends StatelessWidget {
  const UpdatePanelSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(Spacing.screenGutter),
      child: UpdatePanel(),
    );
  }
}
