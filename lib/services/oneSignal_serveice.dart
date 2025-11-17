import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../data/models/data_model.dart';

class OneSignalService {
  static const String appId = '6c709451-e21e-402d-9a66-f205adcfb3d8';
  static const String restApiKey =
      'os_v2_app_nryjiupcdzac3gtg6ic23t5t3dwkrk6zqt7efnvjwpqpxckgxlevsq7p6bzjz2qvodudv72jfjcxdglzaillc5hbla3xrazihwuccwi';

  static Future<void> initialize() async {
    try {
      print('🚀 بدء تهيئة OneSignal...');

      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(appId);

      await OneSignal.Notifications.requestPermission(true);

      print('✅ OneSignal initialized successfully');

      OneSignal.Notifications.addClickListener((event) {
        print('🔔 تم فتح إشعار: ${event.notification.title}');
        print('📦 البيانات: ${event.notification.additionalData}');
      });

      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        print('📬 إشعار وارد في Foreground: ${event.notification.title}');
      });

      final subscription = OneSignal.User.pushSubscription;
      final playerId = subscription.id;
      final token = subscription.token;

      if (playerId != null) {
        print('🆔 OneSignal Player ID: $playerId');
        print('📋 احفظ هذا الـ ID للاختبار!');
      }
      if (token != null) {
        print('📱 FCM Token: $token');
      }

      subscription.addObserver((state) {
        print('🔄 Subscription تغير:');
        print('   Player ID: ${state.current.id}');
        print('   Token: ${state.current.token}');
      });
    } catch (e) {
      print('❌ خطأ في تهيئة OneSignal: $e');
    }
  }

  static Future<void> setExternalUserId(String userId) async {
    try {
      await OneSignal.login(userId);
      print('✅ تم ربط OneSignal بالمستخدم: $userId');
    } catch (e) {
      print('❌ خطأ في ربط المستخدم: $e');
    }
  }

  static Future<void> setUserTags({
    required String stage,
    required int dayInCycle,
    required String unitId,
  }) async {
    try {
      await OneSignal.User.addTags({
        'current_stage': stage,
        'day_in_cycle': dayInCycle.toString(),
        'unit_id': unitId,
        'last_update': DateTime.now().toIso8601String(),
      });
      print('✅ Tags محدثة: stage=$stage, day=$dayInCycle');
    } catch (e) {
      print('❌ خطأ في تحديث Tags: $e');
    }
  }

  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('📤 إرسال إشعار لـ $userId...');

      final url = Uri.parse('https://onesignal.com/api/v1/notifications');

      final body = {
        'app_id': appId,
        'include_external_user_ids': [userId],
        'headings': {'en': title},
        'contents': {'en': message},
        if (data != null) 'data': data,
      };

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Basic $restApiKey',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('✅ تم إرسال الإشعار بنجاح');
        final responseData = jsonDecode(response.body);
        print('📊 Recipients: ${responseData['recipients']}');
      } else {
        print('❌ فشل إرسال الإشعار: ${response.statusCode}');
        print('📄 Body: ${response.body}');
      }
    } catch (e) {
      print('❌ خطأ في إرسال الإشعار: $e');
    }
  }

  // ✅ إرسال إشعار تغيير المرحلة
  static Future<void> sendStageChangeNotification({
    required String userId,
    required IncubationStage oldStage,
    required IncubationStage newStage,
  }) async {
    print('🔄 إرسال إشعار تغيير مرحلة...');

    final feedingPercent = getFeedingPercentage(newStage);

    await sendNotificationToUser(
      userId: userId,
      title: '🔄 انتقال لمرحلة جديدة',
      message:
          'تم الانتقال من ${oldStage.arabicName} إلى ${newStage.arabicName}\n'
          'كمية التغذية الجديدة: $feedingPercent%',
      data: {
        'type': 'stage_change',
        'old_stage': oldStage.name,
        'new_stage': newStage.name,
        'feeding_percent': feedingPercent,
      },
    );

    
  }

  // ✅ إرسال إشعار وقت التغذية
  static Future<void> sendFeedingNotification({
    required String userId,
    required int feedingNumber,
    required IncubationStage currentStage,
  }) async {
    print('🍃 إرسال إشعار تغذية #$feedingNumber...');

    final feedingPercent = getFeedingPercentage(currentStage);
    final stageName = getStageName(currentStage);

    await sendNotificationToUser(
      userId: userId,
      title: '🍃 وقت التغذية $feedingNumber/4',
      message: 'المرحلة: $stageName\n'
          'كمية التغذية: $feedingPercent%\n'
          'تأكد من تقديم الغذاء لدودة القز الآن.',
      data: {
        'type': 'feeding',
        'feeding_number': feedingNumber,
        'stage': currentStage.name,
        'feeding_percent': feedingPercent,
      },
    );
  }

  // ✅ إرسال إشعارات التغذية اليومية (4 مرات)
  static Future<void> scheduleDailyFeedingNotifications({
    required String userId,
    required IncubationStage currentStage,
  }) async {
    print('📅 جدولة إشعارات التغذية اليومية...');

    // في الواقع، الجدولة تتم من OneSignal Dashboard
    // لكن يمكن إرسال إشعار فوري للاختبار

    await sendFeedingNotification(
      userId: userId,
      feedingNumber: 1,
      currentStage: currentStage,
    );
  }

  static int getFeedingPercentage(IncubationStage stage) {
    switch (stage) {
      case IncubationStage.eggIncubation:
        return 0;
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
}
