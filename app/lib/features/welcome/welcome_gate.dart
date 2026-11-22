import 'package:flutter/foundation.dart';

import '../../core/routes.dart';
import 'welcome_store.dart';

class WelcomeGate extends ChangeNotifier {
  WelcomeGate({this._pending = false});

  bool _pending;

  bool get pending => _pending;

  Future<void> load(WelcomeStore store) async {
    _set(!await store.seen());
  }

  void complete() => _set(false);

  void _set(bool value) {
    if (_pending == value) return;
    _pending = value;
    notifyListeners();
  }
}

final welcomeGate = WelcomeGate();

String? welcomeRedirect(WelcomeGate gate, String location) {
  if (gate.pending && location == Routes.home) return Routes.welcome;
  return null;
}
