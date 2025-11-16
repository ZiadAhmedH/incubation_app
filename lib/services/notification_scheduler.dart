import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'local_notification_service.dart';
import '../data/models/data_model.dart';

class NotificationScheduler {
  static const String _currentCycleKey = 'current_cycle_notifications';

  static Future<void> init() async {
    // تهيئة بسيطة
    print('📱 تهيئة جدولة الإشعارات');
  }

  // تحديد نسبة التغذية لكل مرحلة
  static int _getFeedingPercentage(IncubationStage stage) {
    switch (stage) {
      case IncubationStage.eggIncubation:
        return 0; // مرحلة البيض - لا تغذية
      case IncubationStage.eggIncubation:
        return 20; // المرحلة اليرقية الأولى
      case IncubationStage.larvaStage2:
        return 35; // المرحلة اليرقية الثانية
      case IncubationStage.larvaStage3:
        return 50; // المرحلة اليرقية الثالثة
      case IncubationStage.larvaStage4:
        return 65; // المرحلة اليرقية الرابعة
      case IncubationStage.larvaStage5:
        return 80; // المرحلة اليرقية الخامسة
      case IncubationStage.pupa:
        return 0; // مرحلة العذراء - لا تغذية

      default:
        return 0;
    }
  }

  // جدولة إشعارات بسيطة (سيتم تطويرها لاحقاً)
  static Future<void> scheduleStageNotifications({
    required String cycleId,
    required IncubationStage stage,
    required DateTime stageStart,
    required int durationDays,
  }) async {
    final feedingPercent = _getFeedingPercentage(stage);

    // إذا لم تكن هناك حاجة لتغذية في هذه المرحلة
    if (feedingPercent == 0) {
      print('🚫 لا حاجة لإشعارات تغذية في مرحلة ${stage.name}');
      return;
    }

    print(
      '📅 ستتم جدولة إشعارات لمرحلة ${stage.name} بنسبة تغذية ${feedingPercent}%',
    );

    // حفظ معلومات الدورة
    await _saveCycleInfo(cycleId, stage, stageStart, durationDays);

    // إرسال إشعار فوري للتأكد من عمل النظام
    LocalNotificationService.showBasicNotification(
      '🍃 بدء مرحلة ${stage.name}',
      'تذكير: تغذية يومية بنسبة ${feedingPercent}% لمدة ${durationDays} أيام',
    );
  }

  // حفظ معلومات الدورة
  static Future<void> _saveCycleInfo(
    String cycleId,
    IncubationStage stage,
    DateTime stageStart,
    int durationDays,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cycleInfo = {
      'cycleId': cycleId,
      'stage': stage.name,
      'stageStart': stageStart.toIso8601String(),
      'durationDays': durationDays,
      'savedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_currentCycleKey, json.encode(cycleInfo));
  }

  // إعادة جدولة بعد إعادة التشغيل (مبسطة)
  static Future<void> rescheduleAfterReboot() async {
    final prefs = await SharedPreferences.getInstance();
    final cycleInfoString = prefs.getString(_currentCycleKey);

    if (cycleInfoString == null) {
      print('📱 لا توجد دورة محفوظة لإعادة الجدولة');
      return;
    }

    try {
      final cycleInfo = json.decode(cycleInfoString);
      print('🔄 تم العثور على دورة محفوظة: ${cycleInfo['stage']}');

      // إرسال إشعار تذكير
      LocalNotificationService.showBasicNotification(
        '🔄 استئناف المتابعة',
        'تم إعادة تشغيل النظام - مرحلة ${cycleInfo['stage']} نشطة',
      );
    } catch (e) {
      print('❌ خطأ في قراءة الدورة المحفوظة: $e');
    }
  }

  // إلغاء جميع الإشعارات
  static Future<void> cancelAllScheduled() async {
    await LocalNotificationService.cancelAll();
  }

  // مسح معلومات الدورة المحفوظة
  static Future<void> clearSavedCycleInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentCycleKey);
  }

  // إلغاء إشعارات دورة معينة
  static Future<void> cancelCycleNotifications(String cycleId) async {
    await cancelAllScheduled();
    await clearSavedCycleInfo();
  }
}
