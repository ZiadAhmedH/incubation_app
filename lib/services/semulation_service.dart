import 'dart:async';
import '../data/data_sources/remote/firebase_service.dart';
import '../data/models/data_model.dart';
import 'esp32_simulator.dart';

class SimulationService {
  static const bool debugMode = true;

  final List<StageConfig> stageConfigs = [
    StageConfig(
      stage: IncubationStage.eggIncubation,
      durationDays: 2,
      temperatureRange: const TemperatureRange(min: 23, max: 28, optimal: 25),
      humidityRange: const HumidityRange(min: 70, max: 85, optimal: 75),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage1,
      durationDays: 1,
      temperatureRange: const TemperatureRange(min: 24, max: 28, optimal: 26),
      humidityRange: const HumidityRange(min: 70, max: 80, optimal: 75),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage2,
      durationDays: 4,
      temperatureRange: const TemperatureRange(min: 25, max: 28, optimal: 26.5),
      humidityRange: const HumidityRange(min: 70, max: 80, optimal: 75),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage3,
      durationDays: 5,
      temperatureRange: const TemperatureRange(min: 25, max: 27, optimal: 26),
      humidityRange: const HumidityRange(min: 65, max: 75, optimal: 70),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage4,
      durationDays: 6,
      temperatureRange: const TemperatureRange(min: 24, max: 26, optimal: 25),
      humidityRange: const HumidityRange(min: 60, max: 70, optimal: 65),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage5,
      durationDays: 8,
      temperatureRange: const TemperatureRange(min: 23, max: 25, optimal: 24),
      humidityRange: const HumidityRange(min: 60, max: 70, optimal: 65),
    ),
    StageConfig(
      stage: IncubationStage.pupa,
      durationDays: 5,
      temperatureRange: const TemperatureRange(min: 22, max: 26, optimal: 24),
      humidityRange: const HumidityRange(min: 55, max: 65, optimal: 60),
    ),
  ];

  final ESP32Simulator _esp32Simulator = ESP32Simulator();
  final FirebaseService _firebaseService = FirebaseService();
  StreamSubscription<SensorData>? _dataSubscription;

  /// Start simulation with Firebase integration
  void startSimulation({
    required String unitId,
    required IncubationStage currentStage,
    required Function(SensorData) onDataUpdate,
  }) {
    final config = stageConfigs.firstWhere((c) => c.stage == currentStage);

    // Start ESP32 simulator to push data to Firebase
    _esp32Simulator.startSimulation(
      unitId,
      targetTemp: config.temperatureRange.optimal,
      targetHumidity: config.humidityRange.optimal,
    );

    // Stream data from Firebase
    _dataSubscription =
        _firebaseService.streamSensorData(unitId).listen(onDataUpdate);
  }

  /// Get stage configuration
  StageConfig getStageConfig(IncubationStage stage) {
    return stageConfigs.firstWhere((c) => c.stage == stage);
  }

  void stopSimulation() {
    _esp32Simulator.stopSimulation();
    _dataSubscription?.cancel();
  }

  void dispose() {
    _esp32Simulator.dispose();
    _firebaseService.dispose();
    _dataSubscription?.cancel();
  }
}
