import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _noticeDuration = Duration(milliseconds: 2400);

String? readerStartNotice({
  required String? switchedFrom,
  required int startPage,
}) {
  final parts = [
    if (switchedFrom != null) 'Dibaca dari sumber lain.',
    if (startPage > 0) 'Melanjutkan dari halaman ${startPage + 1}.',
  ];
  return parts.isEmpty ? null : parts.join(' ');
}

void announceReaderStart(
  BuildContext context, {
  required String? switchedFrom,
  required int startPage,
}) {
  final text = readerStartNotice(
    switchedFrom: switchedFrom,
    startPage: startPage,
  );
  if (text == null) return;
  ShadToaster.of(context)
      .show(ShadToast(description: Text(text), duration: _noticeDuration));
}
