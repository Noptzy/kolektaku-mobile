import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../features/notifications/notice_texts.dart';
import '../src/rust/dto/follow.dart';

const updatesChannelId = 'updates_v1';
const quietChannelId = 'updates_silent_v1';
const _icon = '@mipmap/ic_launcher';
const _soundName = 'tuturu';

abstract interface class Notifier {
  Future<void> init({void Function(String? payload)? onTap});

  Future<bool> requestPermission();

  Future<bool> isPermitted();

  Future<void> showEvents(List<UpdateEventDto> events, {bool sound = true});

  Future<void> showNotice({required String title, required String body});

  Future<void> showTest();

  Future<String?> launchPayload();
}

class LocalNotifier implements Notifier {
  LocalNotifier([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> init({void Function(String? payload)? onTap}) async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings(_icon),
      ),
      onDidReceiveNotificationResponse: (response) =>
          onTap?.call(response.payload),
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        updatesChannelId,
        'Episode dan chapter baru',
        description:
            'Kabar judul favorit yang punya episode atau chapter baru.',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound(_soundName),
      ),
    );
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        quietChannelId,
        'Episode dan chapter baru (tanpa suara)',
        importance: Importance.defaultImportance,
        playSound: false,
      ),
    );
    _ready = true;
  }

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<bool> isPermitted() async =>
      await _android?.areNotificationsEnabled() ?? false;

  NotificationDetails _details(bool sound) => NotificationDetails(
    android: AndroidNotificationDetails(
      sound ? updatesChannelId : quietChannelId,
      sound
          ? 'Episode dan chapter baru'
          : 'Episode dan chapter baru (tanpa suara)',
      importance: sound ? Importance.high : Importance.defaultImportance,
      priority: sound ? Priority.high : Priority.defaultPriority,
      playSound: sound,
      sound: sound
          ? const RawResourceAndroidNotificationSound(_soundName)
          : null,
    ),
  );

  @override
  Future<void> showEvents(
    List<UpdateEventDto> events, {
    bool sound = true,
  }) async {
    if (events.isEmpty) return;
    if (events.length > maxSeparateNotices) {
      await _plugin.show(
        id: 0,
        title: summaryTitle(events.length),
        body: summaryBody(events),
        notificationDetails: _details(sound),
      );
      return;
    }
    for (final event in events) {
      await _plugin.show(
        id: payloadOf(event).hashCode & 0x7fffffff,
        title: event.title,
        body: noticeBody(event),
        notificationDetails: _details(sound),
        payload: payloadOf(event),
      );
    }
  }

  @override
  Future<void> showNotice({required String title, required String body}) =>
      _plugin.show(
        id: title.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'app_update_v1',
            'Pembaruan aplikasi',
            importance: Importance.defaultImportance,
          ),
        ),
      );

  @override
  Future<void> showTest() => _plugin.show(
    id: 1,
    title: 'Kolektaku',
    body: 'Begini bunyi notifikasi episode dan chapter baru.',
    notificationDetails: _details(true),
  );

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }
}
