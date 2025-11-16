import 'dart:async';
import 'package:flutter/services.dart';
import '../data/models/data_model.dart';
import 'local_notification_service.dart';
import 'semulation_service.dart';

class FeedingScheduleService {
  Timer? _feedingTimer;
  int _feedingCount = 0;
  DateTime? _lastFeedingDay;

  // أوقات التغذية الأربعة في اليوم (في وضع Debug: كل 15 ثانية)
  // في الإنتاج: 6 صباحاً، 12 ظهراً، 6 مساءً، 12 منتصف الليل
  static const List<int> feedingHoursProduction = [6, 12, 18, 24];

  // في وضع Debug: كل 15 ثانية (4 مرات في الدقيقة)
  static const Duration debugFeedingInterval = Duration(seconds: 15);

  void startFeedingSchedule({
    required IncubationCycle cycle,
    required Function() onFeedingTime,
  }) {
    stopFeedingSchedule();

    if (SimulationService.debugMode) {
      _startDebugMode(cycle, onFeedingTime);
    } else {
      _startProductionMode(cycle, onFeedingTime);
    }
  }

  void _startDebugMode(IncubationCycle cycle, Function() onFeedingTime) {
    _feedingCount = 0;
    final currentDay = _getCurrentDay(cycle);
    _lastFeedingDay = currentDay;

    print('🍃 بدء جدول التغذية - وضع Debug (كل 15 ثانية)');

    _feedingTimer = Timer.periodic(debugFeedingInterval, (timer) {
      final newDay = _getCurrentDay(cycle);

      // إعادة تعيين العداد عند بداية يوم جديد
      if (newDay != _lastFeedingDay) {
        _feedingCount = 0;
        _lastFeedingDay = newDay;
        print('📅 يوم جديد: ${_formatDay(newDay)}');
      }

      // إذا لم نكمل 4 مرات في اليوم
      if (_feedingCount < 4) {
        _feedingCount++;
        print(
            '🍃 وقت التغذية ${_feedingCount}/4 - اليوم ${_formatDay(newDay)}');

        _triggerFeedingAlert(cycle, _feedingCount);
        onFeedingTime();
      }
    });
  }

  void _startProductionMode(IncubationCycle cycle, Function() onFeedingTime) {
    print('🍃 بدء جدول التغذية - الوضع الإنتاجي');

    // فحص كل دقيقة
    _feedingTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final now = DateTime.now();
      final hour = now.hour;
      final minute = now.minute;

      // فحص إذا كان الوقت الحالي يطابق أحد أوقات التغذية
      if (minute == 0 && feedingHoursProduction.contains(hour)) {
        _triggerFeedingAlert(cycle, feedingHoursProduction.indexOf(hour) + 1);
        onFeedingTime();
      }
    });
  }

  DateTime _getCurrentDay(IncubationCycle cycle) {
    final elapsed = DateTime.now().difference(cycle.stageStartDate);
    final dayNumber =
        SimulationService.debugMode ? elapsed.inMinutes : elapsed.inDays;

    return cycle.stageStartDate.add(Duration(days: dayNumber));
  }

  String _formatDay(DateTime day) {
    return '${day.day}/${day.month}/${day.year}';
  }

  Future<void> _triggerFeedingAlert(
      IncubationCycle cycle, int feedingNumber) async {
    final stageName = cycle.currentStage.arabicName;
    final feedingPercent = _getFeedingPercentage(cycle.currentStage);

    // اهتزاز
    try {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      await HapticFeedback.heavyImpact();
    } catch (e) {
      print('Vibration error: $e');
    }

    // إشعار
    LocalNotificationService.showBasicNotification(
      '🍃 وقت التغذية ${feedingNumber}/4',
      'المرحلة: $stageName\nكمية التغذية: $feedingPercent%',
    );

    // صوت إشعار إضافي
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      print('Haptic error: $e');
    }
  }

  int _getFeedingPercentage(IncubationStage stage) {
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

  void stopFeedingSchedule() {
    _feedingTimer?.cancel();
    _feedingTimer = null;
    _feedingCount = 0;
    _lastFeedingDay = null;
  }

  void dispose() {
    stopFeedingSchedule();
  }

  // معلومات الحالة
  int get currentFeedingCount => _feedingCount;
  bool get isScheduleActive => _feedingTimer != null && _feedingTimer!.isActive;
}
