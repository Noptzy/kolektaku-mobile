import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../platform/background_checks.dart';
import '../../platform/notifier.dart';
import '../notifications/notification_prefs.dart';
import '../notifications/permission_flow.dart';
import 'settings_widgets.dart';

class NotificationSection extends StatefulWidget {
  const NotificationSection({super.key, this.notifier});

  final Notifier? notifier;

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  late final Notifier _notifier = widget.notifier ?? LocalNotifier();
  bool _enabled = false;
  bool _permitted = false;
  int _hours = defaultHours;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _notifier.init();
    final enabled = await NotificationPrefs.enabled();
    final hours = await NotificationPrefs.hours();
    final permitted = await _notifier.isPermitted();
    if (!mounted) return;
    setState(() {
      _enabled = enabled && permitted;
      _hours = hours;
      _permitted = permitted;
      _loaded = true;
    });
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      await turnOnNotifications(_notifier);
    } else {
      await NotificationPrefs.setEnabled(false);
      await cancelChecks();
    }
    await _load();
  }

  Future<void> _pickHours(int hours) async {
    await NotificationPrefs.setHours(hours);
    if (_enabled) await scheduleChecks(hours);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchRow(
          title: 'Kabari episode dan chapter baru',
          hint: _permitted
              ? 'Favoritmu diperiksa berkala, dengan bunyi tuturu.'
              : 'Izin notifikasi belum diberikan. Nyalakan untuk meminta izin.',
          value: _enabled,
          onChanged: _toggle,
        ),
        ChoiceRow<int>(
          title: 'Seberapa sering diperiksa',
          hint: 'Android menggeser waktunya demi baterai.',
          options: [for (final hours in hourChoices) (hours, '$hours jam')],
          value: _hours,
          onChanged: _pickHours,
        ),
        Padding(
          padding: const EdgeInsets.all(Spacing.screenGutter),
          child: ShadButton.outline(
            key: const Key('notify-test'),
            onPressed: _permitted ? _notifier.showTest : null,
            child: const Text('Coba notifikasi'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
          child: Text(
            'Sebagian HP (Xiaomi, Infinix, dan sejenisnya) menghentikan tugas '
            'latar belakang untuk menghemat baterai. Bila kabarnya tidak '
            'datang, izinkan Kolektaku berjalan di latar belakang lewat '
            'pengaturan baterai HP.',
            style: theme.textTheme.muted,
          ),
        ),
      ],
    );
  }
}
