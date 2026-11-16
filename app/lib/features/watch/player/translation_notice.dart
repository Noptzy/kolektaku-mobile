import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'player_session.dart';

class TranslationNotice extends StatefulWidget {
  const TranslationNotice({super.key, required this.session});

  final PlayerSession session;

  @override
  State<TranslationNotice> createState() => _TranslationNoticeState();
}

class _TranslationNoticeState extends State<TranslationNotice> {
  ValueNotifier<String?> get _notice =>
      widget.session.extras.subtitleCues.notice;

  @override
  void initState() {
    super.initState();
    _notice.addListener(_show);
  }

  void _show() {
    final text = _notice.value;
    if (text == null || !mounted) return;
    ShadToaster.of(context).show(ShadToast(description: Text(text)));
  }

  @override
  void dispose() {
    _notice.removeListener(_show);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
