import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/models/data_model.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OneSignalService {
  static final String appId = dotenv.env['ONESIGNAL_APP_ID']!;
  static final String restApiKey = dotenv.env['ONESIGNAL_REST_API_KEY']!;

  // Initialize OneSignal
  static Future<void> initialize() async {
    try {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(appId);
      await OneSignal.Notifications.requestPermission(true);
      print('✅ OneSignal initialized');
    } catch (e) {
      print('❌ OneSignal initialization failed: $e');
    }
  }

  // Schedules a notification for a specific time (works in killed state)
  static Future<void> scheduleNotification({
    required String userId,
    required String title,
    required String message,
    required DateTime sendAt,
    Map<String, dynamic>? data,
    String androidSound =
        'notification.mp3', // <-- default to your sound (no extension)
    String iosSound =
        'notification.mp3', // <-- default to your sound (with extension)
  }) async {
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    final body = {
      'app_id': appId,
      'include_external_user_ids': [userId],
      'headings': {'en': title, 'ar': title},
      'contents': {'en': message, 'ar': message},
      'send_after': sendAt.toUtc().toIso8601String(),
      if (data != null) 'data': data,
      'android_sound': androidSound, // <-- add this
      'ios_sound': iosSound, // <-- add this
    };
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Basic $restApiKey',
      },
      body: jsonEncode(body),
    );
    print('OneSignal response: ${response.statusCode} ${response.body}');
  }

  static Future<void> setUserTags({
    required String stage,
    required int dayInCycle,
    required String unitId,
  }) async {
    final url = Uri.parse('https://onesignal.com/api/v1/apps/$appId/users/tag');
    final body = {
      'app_id': appId,
      'tags': {
        'current_stage': stage,
        'day_in_cycle': dayInCycle.toString(),
        'unit_id': unitId,
        'last_update': DateTime.now().toIso8601String(),
      }
    };
  }

  // Send stage change notification immediately (works in all app states)
  static Future<void> sendStageChangeNotification({
    required String userId,
    required IncubationStage oldStage,
    required IncubationStage newStage,
  }) async {
    final feedingPercent = getFeedingPercentage(newStage);
    final title = '🔄 انتقال لمرحلة جديدة';
    final message =
        'تم الانتقال من ${oldStage.arabicName} إلى ${newStage.arabicName}\n'
        'كمية التغذية الجديدة: $feedingPercent%';
    final data = {
      'type': 'stage_change',
      'old_stage': oldStage.name,
      'new_stage': newStage.name,
      'feeding_percent': feedingPercent,
    };
    // Send immediately (no scheduling)
    await scheduleNotification(
      userId: userId,
      title: title,
      message: message,
      sendAt: DateTime.now(),
      data: data,
    );
  }

  /// Link OneSignal notifications to a specific user
  static Future<void> setExternalUserId(String userId) async {
    try {
      await OneSignal.login(userId);
      print('✅ تم ربط OneSignal بالمستخدم: $userId');
    } catch (e) {
      print('❌ خطأ في ربط المستخدم بـ OneSignal: $e');
    }
  }

  /// Send an immediate notification to a user (works in all app states)
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
    String androidSound = 'notification',
    String iosSound = 'notification.mp3',
  }) async {
    final url = Uri.parse('https://onesignal.com/api/v1/notifications');
    final body = {
      'app_id': appId,
      'include_external_user_ids': [userId],
      'headings': {'en': title, 'ar': title},
      'contents': {'en': message, 'ar': message},
      if (data != null) 'data': data,
      'android_sound': androidSound, // <-- add this
      'ios_sound': iosSound, // <-- add this
    };
    await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Basic $restApiKey',
      },
      body: jsonEncode(body),
    );
    print('✅ تم إرسال إشعار إلى المستخدم: $userId');
  }

  static int getFeedingPercentage(IncubationStage stage) {
    switch (stage) {
      case IncubationStage.larvaStage1:
        return 20;
      case IncubationStage.larvaStage2:
        return 35;
      case IncubationStage.larvaStage3:
        return 50;
      case IncubationStage.larvaStage4:
        return 65;
      case IncubationStage.larvaStage5:
        return 80;
      case IncubationStage.pupa:
        return 0;
      default:
        return 0;
    }
  }

  static String getStageName(IncubationStage stage) {
    return stage.arabicName;
  }

  static Future<void> scheduleFullCycleFeedings({
    required String userId,
    required IncubationStage currentStage,
    int days = 32,
  }) async {
    final feedingPercent = OneSignalService.getFeedingPercentage(currentStage);
    final stageName = OneSignalService.getStageName(currentStage);
    final now = DateTime.now();

    for (int day = 0; day < days; day++) {
      final baseTime = now.add(Duration(minutes: day));
      for (int i = 0; i < 4; i++) {
        final scheduledTime = baseTime.add(Duration(seconds: i * 15));
        try {
          await OneSignalService.scheduleNotification(
            userId: userId,
            title: '🍃 وقت التغذية ${i + 1}/4',
            message: 'اليوم ${day + 1} - المرحلة: $stageName\n'
                'كمية التغذية: $feedingPercent%\n'
                'تأكد من تقديم الغذاء لدودة القز الآن.',
            sendAt: scheduledTime,
            data: {
              'type': 'feeding',
              'feeding_number': i + 1,
              'stage': currentStage.name,
              'feeding_percent': feedingPercent,
              'simulated_day': day + 1,
            },
          );
          print(
              '✅ Scheduled feeding notification: Day ${day + 1}, Feeding ${i + 1}');
        } catch (e) {
          print(
              '❌ Failed to schedule feeding notification: Day ${day + 1}, Feeding ${i + 1}, Error: $e');
        }
      }
    }
    print('✅ تم جدولة إشعارات التغذية لـ $days يوم (دقيقة) قادمة');
  }

  static Future<void> scheduleAllStageTransitionNotifications({
    required String userId,
    required List<StageConfig> stages,
    required DateTime cycleStart,
  }) async {
    DateTime baseTime = cycleStart;
    for (final stage in stages) {
      final title = '🔄 انتقال لمرحلة جديدة';
      final message = 'بدأت المرحلة: ${stage.stage.arabicName}';

      try {
        await OneSignalService.scheduleNotification(
          userId: userId,
          title: title,
          message: message,
          sendAt: baseTime,
          data: {
            'type': 'stage_change',
            'stage': stage.stage.name,
          },
        );
        print(
            '✅ Scheduled stage transition notification: ${stage.stage.arabicName} at $baseTime');
      } catch (e) {
        print(
            '❌ Failed to schedule stage transition notification: ${stage.stage.arabicName}, Error: $e');
      }

      baseTime = baseTime.add(Duration(minutes: stage.durationDays));
    }
    print('✅ تم جدولة إشعارات انتقال المراحل لجميع المراحل');
  }
}
