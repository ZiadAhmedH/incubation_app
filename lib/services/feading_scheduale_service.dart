import 'dart:async';
import 'oneSignal_serveice.dart';
import '../data/models/data_model.dart';

class FeedingNotificationService {
  /// Schedule feeding notifications (4 times per minute = every 15 seconds)
  Future<void> scheduleFeedingNotifications({
    required String userId,
    required IncubationStage currentStage,
  }) async {
    print('📅 جدولة إشعارات التغذية (4 مرات في الدقيقة)...');

    final feedingPercent = OneSignalService.getFeedingPercentage(currentStage);
    final stageName = OneSignalService.getStageName(currentStage);

    // 1 day = 1 minute → 4 feedings per minute = every 15 seconds
    final feedingIntervals = [0, 15, 30, 45];
    final now = DateTime.now();

    for (int i = 0; i < feedingIntervals.length; i++) {
      final scheduledTime = now.add(Duration(seconds: feedingIntervals[i]));

      await OneSignalService.scheduleNotification(
        userId: userId,
        title: '🍃 وقت التغذية ${i + 1}/4',
        message: 'المرحلة: $stageName\n'
            'كمية التغذية: $feedingPercent%\n'
            'تأكد من تقديم الغذاء لدودة القز الآن.',
        sendAt: scheduledTime,
        data: {
          'type': 'feeding',
          'feeding_number': i + 1,
          'stage': currentStage.name,
          'feeding_percent': feedingPercent,
        },
      );
      print(
          '⏰ جدولة تغذية ${i + 1}/4 في: ${scheduledTime.toString()} (+${feedingIntervals[i]}s)');
    }
    print('✅ تم جدولة 4 إشعارات تغذية للدقيقة القادمة');
  }

  /// No timers needed; these are now NO-OPs
  void startFeedingNotifications({
    required String userId,
    required IncubationStage currentStage,
  }) {
    // Not used anymore
  }

  void stopFeedingNotifications() {
    // Not used anymore
  }

  void updateStage(IncubationStage newStage) {
    // Not used anymore
  }

  void dispose() {
    // Not used anymore
  }
}
