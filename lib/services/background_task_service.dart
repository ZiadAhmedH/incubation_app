// import 'package:workmanager/workmanager.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/services.dart';

// import 'local_notification_service.dart';

// class WorkmanagerService {
//   static const String feedingTaskName = 'feedingTask';
//   static const String uniqueTaskName = 'incubationFeedingTask';

//   static Future<void> initialize() async {
//     await Workmanager().initialize(
//       callbackDispatcher,
//       isInDebugMode: true, // للتطوير فقط
//     );
//   }

//   static Future<void> startPeriodicTask() async {
//     await Workmanager().registerPeriodicTask(
//       uniqueTaskName,
//       feedingTaskName,
//       frequency:
//           const Duration(minutes: 15), // كل 15 دقيقة (الحد الأدنى في Android)
//       initialDelay: const Duration(seconds: 10),
//       constraints: Constraints(
//         networkType: NetworkType.not_required,
//         requiresBatteryNotLow: false,
//         requiresCharging: false,
//         requiresDeviceIdle: false,
//         requiresStorageNotLow: false,
//       ),
//     );
//     print('✅ Workmanager: تم جدولة المهمة الدورية');
//   }

//   static Future<void> cancelAllTasks() async {
//     await Workmanager().cancelAll();
//     print('❌ Workmanager: تم إلغاء جميع المهام');
//   }
// }

// @pragma('vm:entry-point')
// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     print('🔄 Workmanager: تشغيل المهمة - $task');

//     try {
//       // تهيئة الإشعارات
//       await LocalNotificationService.init();

//       // قراءة البيانات من SharedPreferences
//       final prefs = await SharedPreferences.getInstance();
//       final isActive = prefs.getBool('cycle_active') ?? false;

//       if (!isActive) {
//         print('⚠️ لا توجد دورة نشطة');
//         return Future.value(true);
//       }

//       final currentStageIndex = prefs.getInt('current_stage') ?? 0;
//       final feedingCount = prefs.getInt('feeding_count_today') ?? 0;
//       final lastFeedingDay = prefs.getString('last_feeding_day') ?? '';

//       final now = DateTime.now();
//       final currentDay = '${now.year}-${now.month}-${now.day}';

//       // إعادة تعيين العداد في يوم جديد
//       if (currentDay != lastFeedingDay) {
//         await prefs.setInt('feeding_count_today', 0);
//         await prefs.setString('last_feeding_day', currentDay);
//         print('📅 يوم جديد: تم إعادة تعيين عداد التغذية');
//       }

//       // إرسال إشعار تغذية (4 مرات في اليوم)
//       final newFeedingCount = prefs.getInt('feeding_count_today') ?? 0;
//       if (newFeedingCount < 4) {
//         final stageName = _getStageName(currentStageIndex);
//         final feedingPercent = _getFeedingPercentage(currentStageIndex);

//         // اهتزاز
//         try {
//           await HapticFeedback.heavyImpact();
//           await Future.delayed(const Duration(milliseconds: 200));
//           await HapticFeedback.heavyImpact();
//         } catch (e) {
//           print('⚠️ Vibration error: $e');
//         }

//         // إشعار
//          LocalNotificationService.showBasicNotification(
//           '🍃 وقت التغذية ${newFeedingCount + 1}/4',
//           'المرحلة: $stageName\nكمية التغذية: $feedingPercent%',
//         );

//         await prefs.setInt('feeding_count_today', newFeedingCount + 1);
//         print('✅ تم إرسال إشعار التغذية ${newFeedingCount + 1}/4');
//       } else {
//         print('✅ تم إكمال جميع وجبات اليوم (4/4)');
//       }

//       return Future.value(true);
//     } catch (e) {
//       print('❌ خطأ في تنفيذ المهمة: $e');
//       return Future.value(false);
//     }
//   });
// }

// String _getStageName(int index) {
//   final stages = [
//     'حضانة البيض',
//     'اليرقة المرحلة 1',
//     'اليرقة المرحلة 2',
//     'اليرقة المرحلة 3',
//     'اليرقة المرحلة 4',
//     'اليرقة المرحلة 5',
//     'الشرنقة',
//   ];
//   return index < stages.length ? stages[index] : 'غير معروف';
// }

// int _getFeedingPercentage(int stageIndex) {
//   final percentages = [0, 20, 35, 50, 65, 80, 0];
//   return stageIndex < percentages.length ? percentages[stageIndex] : 0;
// }



import 'package:flutter/services.dart';
import '../data/models/data_model.dart';

class FeedingAlarmService {
  static const MethodChannel _channel =
      MethodChannel('incubation_app/feeding_alarms');

  // الأوقات الثابتة للتغذية اليومية
  static const List<Map<String, int>> feedingTimes = [
    {'hour': 9, 'minute': 0},   // 9:00 صباحاً
    {'hour': 12, 'minute': 0},  // 12:00 ظهراً
    {'hour': 16, 'minute': 0},  // 4:00 عصراً
    {'hour': 21, 'minute': 0},  // 9:00 مساءً
  ];

  /// جدولة جميع إشعارات التغذية اليومية
  static Future<void> scheduleAllDailyFeedings({
    required IncubationStage currentStage,
  }) async {
    final stageName = currentStage.arabicName;
    final feedingPercent = _getFeedingPercentage(currentStage);

    try {
      for (int i = 0; i < feedingTimes.length; i++) {
        await _channel.invokeMethod('scheduleFeeding', {
          'hour': feedingTimes[i]['hour'],
          'minute': feedingTimes[i]['minute'],
          'feedingNumber': i + 1,
          'stageName': stageName,
          'feedingPercent': feedingPercent,
        });
      }
      print('✅ تم جدولة ${feedingTimes.length} إشعارات تغذية يومية');
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