import 'package:flutter/widgets.dart';

import '../../src/rust/dto/library.dart';
import '../../widgets/rail.dart';
import 'home_actions.dart';
import 'resume_tile.dart';

class ResumeRail extends StatelessWidget {
  const ResumeRail({super.key, required this.items, required this.actions});

  final List<ProgressDto> items;
  final HomeActions actions;

  @override
  Widget build(BuildContext context) {
    return Rail(
      title: 'Lanjutkan',
      height: resumeTileHeight(MediaQuery.textScalerOf(context)),
      itemCount: items.length,
      itemBuilder: (context, index) => ResumeTile(
        progress: items[index],
        onTap: () => actions.onResume(items[index]),
      ),
    );
  }
}
