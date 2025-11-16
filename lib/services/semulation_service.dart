import 'dart:async';
import 'dart:math';
import '../data/models/data_model.dart';

class SimulationService {
  static const bool debugMode = true; // للتطوير: دقيقة = يوم

  final List<StageConfig> stageConfigs = [
    StageConfig(
      stage: IncubationStage.eggIncubation,
      durationDays: 12, // 12 يوم
      temperatureRange: const TemperatureRange(min: 23, max: 28, optimal: 25),
      humidityRange: const HumidityRange(min: 70, max: 85, optimal: 75),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage1,
      durationDays: 4, // 4 أيام
      temperatureRange: const TemperatureRange(min: 24, max: 28, optimal: 26),
      humidityRange: const HumidityRange(min: 70, max: 80, optimal: 75),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage2,
      durationDays: 4, // 4 أيام
      temperatureRange: const TemperatureRange(min: 25, max: 28, optimal: 26.5),
      humidityRange: const HumidityRange(min: 70, max: 80, optimal: 75),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage3,
      durationDays: 5, // 5 أيام
      temperatureRange: const TemperatureRange(min: 25, max: 27, optimal: 26),
      humidityRange: const HumidityRange(min: 65, max: 75, optimal: 70),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage4,
      durationDays: 6, // 6 أيام
      temperatureRange: const TemperatureRange(min: 24, max: 26, optimal: 25),
      humidityRange: const HumidityRange(min: 60, max: 70, optimal: 65),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage5,
      durationDays: 8, // 8 أيام
      temperatureRange: const TemperatureRange(min: 23, max: 25, optimal: 24),
      humidityRange: const HumidityRange(min: 60, max: 70, optimal: 65),
    ),
    StageConfig(
      stage: IncubationStage.pupa,
      durationDays: 5, // 5 أيام (مرحلة الشرنقة)
      temperatureRange: const TemperatureRange(min: 22, max: 26, optimal: 24),
      humidityRange: const HumidityRange(min: 55, max: 65, optimal: 60),
    ),
  ];

  Timer? _simulationTimer;
  final Random _random = Random();

  double _currentTemp = 25.0;
  double _currentHumidity = 75.0;
  bool _fanOn = false;
  bool _heaterOn = false;

  void startSimulation({
    required IncubationStage currentStage,
    required Function(SensorData) onDataUpdate,
  }) {
    _simulationTimer?.cancel();

    final config = stageConfigs.firstWhere((c) => c.stage == currentStage);
    _currentTemp = config.temperatureRange.optimal;
    _currentHumidity = config.humidityRange.optimal;

    _simulationTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        _simulateEnvironment(config);

        final sensorData = SensorData(
          temperature: _currentTemp,
          humidity: _currentHumidity,
          fanOn: _fanOn,
          heaterOn: _heaterOn,
          timestamp: DateTime.now(),
        );

        onDataUpdate(sensorData);
      },
    );
  }

  void _simulateEnvironment(StageConfig config) {
    // محاكاة التغييرات
    _currentTemp += (_random.nextDouble() - 0.5) * 0.5;
    _currentHumidity += (_random.nextDouble() - 0.5) * 2;

    // التحكم التلقائي
    if (_currentTemp < config.temperatureRange.min) {
      _heaterOn = true;
      _fanOn = false;
      _currentTemp += 0.3;
    } else if (_currentTemp > config.temperatureRange.max) {
      _heaterOn = false;
      _fanOn = true;
      _currentTemp -= 0.3;
    } else {
      _heaterOn = false;
      _fanOn = false;
    }

    if (_currentHumidity < config.humidityRange.min) {
      _currentHumidity += 0.5;
    } else if (_currentHumidity > config.humidityRange.max) {
      _currentHumidity -= 0.5;
    }
  }

  void updateDeviceControl({required bool fan, required bool heater}) {
    _fanOn = fan;
    _heaterOn = heater;
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
  }

  void dispose() {
    _simulationTimer?.cancel();
  }
}
