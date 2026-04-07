import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotifService {
  final notif = FlutterLocalNotificationsPlugin();

  init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notif.initialize(InitializationSettings(android: android));
  }

  show() async {
    await notif.show(
      0,
      "Rappel",
      "N'oubliez pas votre habitude",
      NotificationDetails(android: AndroidNotificationDetails("id", "habit")),
    );
  }
}
