import 'dart:async';
import '../../../data/models/data_model.dart';
import '../../../services/semulation_service.dart';
import '../../../data/data_sources/remote/firebase_service.dart';
import '../../../data/data_sources/local/local_storage_service.dart';

/// واجهة بسيطة لفحص انتهاء المرحلة والانتقال
class StageMonitor {
  final SimulationService _sim;
  final FirebaseService _fb;
  final LocalStorageService _local;

  Timer? _timer;

  StageMonitor(this._sim, this._fb, this._local);

  /// يبدأ المؤقت الذي يفحص بشكل دوري ويستدعي [onCheck] لتمرير الحالة الحالية
  void start(IncubationCycle cycle, void Function() onCheck) {
    stop();
    final interval = SimulationService.debugMode
        ? const Duration(seconds: 10)
        : const Duration(minutes: 1);
    _timer = Timer.periodic(interval, (_) => onCheck());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() => stop();

  /// فحص وحساب ما إذا يجب الانتقال (تعيد true لو تحتاج انتقال)
  bool shouldTransition(IncubationCycle cycle) {
    final config = cycle.stages.firstWhere(
      (s) => s.stage == cycle.currentStage,
    );
    final elapsed = DateTime.now().difference(cycle.stageStartDate);
    final passed = SimulationService.debugMode
        ? elapsed.inMinutes
        : elapsed.inDays;
    return passed >= config.durationDays;
  }

  /// ابقَ هنا فقط للحفظ أو أي عمليات متعلقة بالتحويل إن احتجت
  Future<void> persistStageChange(
    String userId,
    IncubationCycle updatedCycle,
  ) async {
    try {
      await _fb.saveIncubationCycle(userId, updatedCycle);
      await _local.saveCurrentStage(updatedCycle.currentStage);
    } catch (e) {
      // log error
      print('StageMonitor.persistStageChange error: $e');
    }
  }
}
