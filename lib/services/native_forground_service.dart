import 'package:flutter/services.dart';
import '../data/models/data_model.dart';

class FeedingAlarmService {
  static const MethodChannel _channel =
      MethodChannel('incubation_app/feeding_alarms');

  // الأوقات الثابتة للتغذية اليومية (للإنتاج)
  static const List<Map<String, int>> feedingTimes = [
    {'hour': 9, 'minute': 0}, // 9:00 صباحاً
    {'hour': 12, 'minute': 0}, // 12:00 ظهراً
    {'hour': 16, 'minute': 0}, // 4:00 عصراً
    {'hour': 21, 'minute': 0}, // 9:00 مساءً
  ];

  // ✅ أوقات اختبار: 1–4 دقيقة من الآن
  static List<Map<String, int>> _testFeedingTimes() {
    final now = DateTime.now();
    return [
      {'hour': now.hour, 'minute': (now.minute + 1) % 60},
      {'hour': now.hour, 'minute': (now.minute + 2) % 60},
      {'hour': now.hour, 'minute': (now.minute + 3) % 60},
      {'hour': now.hour, 'minute': (now.minute + 4) % 60},
    ];
  }

  /// جدولة جميع إشعارات التغذية اليومية
  static Future<void> scheduleAllDailyFeedings({
    required IncubationStage currentStage,
    bool isTest = false, // ✅ مهم للاختبار
  }) async {
    final stageName = currentStage.arabicName;
    final feedingPercent = _getFeedingPercentage(currentStage);

    // استخدم أوقات الاختبار أو الإنتاج
    final times = isTest ? _testFeedingTimes() : feedingTimes;

    try {
      for (int i = 0; i < times.length; i++) {
        await _channel.invokeMethod('scheduleFeeding', {
          'hour': times[i]['hour'],
          'minute': times[i]['minute'],
          'feedingNumber': i + 1,
          'stageName': stageName,
          'feedingPercent': feedingPercent,
        });
      }
      print(
          '✅ تم جدولة ${times.length} إشعارات تغذية ${isTest ? "للاختبار" : "يومية"}');

      if (isTest) {
        final first = times.first;
        print(
          '⏰ أول إشعار تقريباً الساعة '
          '${first['hour']}:${first['minute'].toString().padLeft(2, '0')} (بعد حوالي دقيقة من دلوقتي)',
        );
        print(
            '🔔 اقفل التطبيق تماماً (Kill) واستنى دقيقة – لو وصلك إشعار يبقى شغال في killed.');
      }
    } catch (e) {
      print('❌ خطأ في جدولة الإشعارات: $e');
    }
  }

  /// إلغاء جميع الإشعارات المجدولة
  static Future<void> cancelAllFeedings() async {
    try {
      await _channel.invokeMethod('cancelAllFeedings');
      print('✅ تم إلغاء جميع إشعارات التغذية');
    } catch (e) {
      print('❌ خطأ في إلغاء الإشعارات: $e');
    }
  }

  /// حساب نسبة التغذية حسب المرحلة
  static int _getFeedingPercentage(IncubationStage stage) {
    switch (stage) {
      case IncubationStage.eggIncubation:
        return 0; // البيض لا يحتاج تغذية
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
        return 0; // الشرنقة لا تحتاج تغذية
      default:
        return 0;
    }
  }

  /// الحصول على وصف الوقت بالعربية
  static String getTimeDescription(int index) {
    if (index < 0 || index >= feedingTimes.length) return '';

    final time = feedingTimes[index];
    final hour = time['hour']!;
    final minute = time['minute']!;

    final period = hour < 12 ? 'صباحاً' : (hour < 18 ? 'ظهراً' : 'مساءً');
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}
