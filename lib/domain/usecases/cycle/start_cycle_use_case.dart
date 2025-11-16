import 'package:incubation_app/services/semulation_service.dart';

import '../../../data/models/data_model.dart';
import '../../../data/repositories/incubation_repository.dart';
import '../../../services/notification_scheduler.dart';


class StartCycleUseCase {
  final IncubationRepository _repository;
  final SimulationService _simulation;

  StartCycleUseCase(this._repository, this._simulation);

  Future<IncubationCycle> call(UserData user) async {
    final now = DateTime.now();
    final cycle = IncubationCycle(
      id: 'cycle-${now.millisecondsSinceEpoch}',
      startDate: now,
      currentStage: IncubationStage.eggIncubation,
      stageStartDate: now,
      totalDuration: 44,
      stages: _simulation.stageConfigs,
      isActive: true,
    );

    await _repository.saveCycle(user.userName, cycle);

    await NotificationScheduler.scheduleStageNotifications(
      cycleId: cycle.id,
      stage: cycle.currentStage,
      stageStart: cycle.stageStartDate,
      durationDays: cycle.stages
          .firstWhere(
            (s) => s.stage == cycle.currentStage,
            orElse: () => _getDefaultConfig(cycle.currentStage),
          )
          .durationDays,
    );

    return cycle;
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
