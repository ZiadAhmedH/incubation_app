import '../../../data/models/data_model.dart';
import '../../../data/repositories/incubation_repository.dart';
import '../../../services/notification_scheduler.dart';

class TransitionStageUseCase {
  final IncubationRepository _repository;

  TransitionStageUseCase(this._repository,);

  Future<IncubationCycle?> call(String userId, IncubationCycle current) async {
    final currentIndex = current.currentStage.order;
    final allStages = IncubationStage.values;

    if (currentIndex >= allStages.length - 1) {
      final completed = current.copyWith(isActive: false);
      await _repository.saveCycle(userId, completed);
      return completed;
    }

    final oldStage = current.currentStage;
    final newStage = allStages[currentIndex + 1];
    final updated = current.copyWith(
      currentStage: newStage,
      stageStartDate: DateTime.now(),
    );

    await _repository.saveStageTransition(userId, oldStage, newStage);
    await _repository.saveCycle(userId, updated);

    await NotificationScheduler.scheduleStageNotifications(
      cycleId: updated.id,
      stage: newStage,
      stageStart: updated.stageStartDate,
      durationDays: updated.stages
          .firstWhere(
            (s) => s.stage == newStage,
            orElse: () => _getDefaultConfig(newStage),
          )
          .durationDays,
    );

    return updated;
  }

  StageConfig _getDefaultConfig(IncubationStage stage) {
    return StageConfig(
      stage: stage,
      durationDays: 0,
      temperatureRange: const TemperatureRange(min: 20, max: 30, optimal: 25),
      humidityRange: const HumidityRange(min: 50, max: 80, optimal: 65),
    );
  }
}
