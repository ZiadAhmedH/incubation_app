import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class LocalNotificationService {
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static StreamController<NotificationResponse> streamController =
      StreamController();
  static onTap(NotificationResponse notificationResponse) {
    // log(notificationResponse.id!.toString());
    // log(notificationResponse.payload!.toString());
    streamController.add(notificationResponse);
    // Navigator.push(context, route);
  }

  static Future init() async {
    InitializationSettings settings = const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    flutterLocalNotificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onTap,
      onDidReceiveBackgroundNotificationResponse: onTap,
    );
  }

  //basic Notification
  static void showBasicNotification(String title, String body) async {
    AndroidNotificationDetails android = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(
        'long_notification_sound'.split('.').first,
      ),
    );
    NotificationDetails details = NotificationDetails(android: android);

    try {
      // try showing with custom raw sound
      await flutterLocalNotificationsPlugin.show(0, title, body, details);
    } catch (e) {
      // fallback to default sound if custom resource missing or other platform error
      final androidFallback = AndroidNotificationDetails(
        'channel_id',
        'channel_name',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      );
      final detailsFallback = NotificationDetails(android: androidFallback);
      try {
        await flutterLocalNotificationsPlugin.show(
          0,
          title,
          body,
          detailsFallback,
        );
      } catch (e2) {
        // last resort: log and ignore
        print('Notification show failed: $e2');
      }
    }
  }
}
