import 'package:flutter/widgets.dart';

import 'state_view.dart';

class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return StateView.empty(
      title: title,
      message: 'Layar ini sedang disiapkan.',
    );
  }
}
