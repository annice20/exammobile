import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifService {
  static final NotifService instance = NotifService._();
  NotifService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  /// Notification immédiate (test / rappel manuel)
  Future<void> showNow({String title = 'Rappel', String body = 'N\'oubliez pas vos habitudes !'}) async {
    await _plugin.show(
      0, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_channel', 'Habitudes',
          channelDescription: 'Rappels d\'habitudes',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  /// Annuler toutes les notifications
  Future<void> cancelAll() async => _plugin.cancelAll();
}
