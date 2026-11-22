import 'package:flutter_riverpod/flutter_riverpod.dart';

class SwipeToastData {
  const SwipeToastData({
    required this.id,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final int id;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;
}

class SwipeToastController extends Notifier<SwipeToastData?> {
  int _issued = 0;

  @override
  SwipeToastData? build() => null;

  void show({
    required String message,
    required String actionLabel,
    required Future<void> Function() onAction,
  }) {
    state = SwipeToastData(
      id: ++_issued,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void dismiss([int? id]) {
    if (id != null && state?.id != id) return;
    state = null;
  }
}

final swipeToastProvider =
    NotifierProvider<SwipeToastController, SwipeToastData?>(
      SwipeToastController.new,
    );
