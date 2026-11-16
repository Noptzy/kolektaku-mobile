import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/theme/kolektaku_tokens.dart';
import '../../platform/background_checks.dart';
import '../../platform/notifier.dart';
import '../../src/rust/api/follow.dart' as follow;
import '../../src/rust/dto/follow.dart';
import '../notifications/notification_prefs.dart';
import '../notifications/permission_flow.dart';
import 'settings_widgets.dart';

class NotificationSection extends StatefulWidget {
  const NotificationSection({
    super.key,
    this.notifier,
    this.check = follow.checkFollowedUpdates,
  });

  final Notifier? notifier;
  final Future<List<UpdateEventDto>> Function() check;

  @override
  State<NotificationSection> createState() => _NotificationSectionState();
}

class _NotificationSectionState extends State<NotificationSection> {
  late final Notifier _notifier = widget.notifier ?? LocalNotifier();
  bool _enabled = false;
  bool _permitted = false;
  int _hours = defaultHours;
  bool _loaded = false;
  bool _checking = false;

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

  void _say(String message) {
    if (!mounted) return;
    ShadToaster.of(context).show(ShadToast(description: Text(message)));
  }

  Future<bool> _allowed() async {
    if (_permitted) return true;
    await _notifier.init();
    final granted = await _notifier.requestPermission();
    await _load();
    if (!granted) {
      _say('Izin notifikasi ditolak. Aktifkan lewat pengaturan HP.');
    }
    return granted;
  }

  Future<void> _test() async {
    if (!await _allowed()) return;
    try {
      await _notifier.showTest();
    } on Object {
      _say(
        'Notifikasi tidak bisa ditampilkan. Periksa pengaturan notifikasi Kolektaku di HP.',
      );
    }
  }

  Future<void> _checkNow() async {
    if (_checking || !await _allowed()) return;
    setState(() => _checking = true);
    try {
      final events = await widget.check();
      if (events.isEmpty) {
        _say(
          'Belum ada episode atau chapter baru. Kolektaku mencatat keadaan '
          'favoritmu sekarang dan mengabari bila ada yang baru.',
        );
      } else {
        await _notifier.showEvents(events);
        _say('${events.length} kabar baru dikirim sebagai notifikasi.');
      }
    } on Object {
      _say('Belum bisa memeriksa. Coba lagi sebentar lagi.');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
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
          padding: const EdgeInsets.fromLTRB(
            Spacing.screenGutter,
            Spacing.screenGutter,
            Spacing.screenGutter,
            Spacing.sm,
          ),
          child: ShadButton.outline(
            key: const Key('notify-test'),
            onPressed: _test,
            child: const Text('Coba notifikasi'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.screenGutter),
          child: ShadButton.outline(
            key: const Key('notify-check'),
            enabled: !_checking,
            onPressed: _checkNow,
            child: Text(_checking ? 'Memeriksa…' : 'Periksa sekarang'),
          ),
        ),
        const SizedBox(height: Spacing.md),
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
