import 'dart:async';
import 'dart:math';
import '../models/data_model.dart';

class SimulationService {
  Timer? _simulationTimer;
  final Random _random = Random();
  
  // وضع Debug - كل دقيقة = يوم واحد
  static const bool debugMode = true; // غيرها لـ false في الإنتاج
  
  double _currentTemp = 25.0;
  double _currentHumidity = 75.0;
  bool _fanOn = false;
  bool _heaterOn = false;

  final List<StageConfig> stageConfigs = [
    StageConfig(
      stage: IncubationStage.eggIncubation,
      durationDays: debugMode ? 1 : 10, // دقيقة واحدة في وضع Debug
      temperatureRange: const TemperatureRange(min: 28, max: 29, optimal: 28.5),
      humidityRange: const HumidityRange(min: 80, max: 90, optimal: 85),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage1,
      durationDays: debugMode ? 1 : 7,
      temperatureRange: const TemperatureRange(min: 26, max: 28, optimal: 27),
      humidityRange: const HumidityRange(min: 75, max: 85, optimal: 80),
      feeding: const FeedingSchedule(
        frequency: 4,
        foodType: 'أوراق التوت الطازجة',
        notes: 'تقديم أوراق طازجة 4 مرات يومياً',
      ),
      cleaning: const CleaningSchedule(
        frequency: 2,
        notes: 'تنظيف وإزالة الفضلات مرتين يومياً',
      ),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage2,
      durationDays: debugMode ? 1 : 7,
      temperatureRange: const TemperatureRange(min: 25, max: 27, optimal: 26),
      humidityRange: const HumidityRange(min: 70, max: 80, optimal: 75),
      feeding: const FeedingSchedule(
        frequency: 4,
        foodType: 'أوراق التوت',
        notes: 'زيادة كمية الغذاء',
      ),
      cleaning: const CleaningSchedule(
        frequency: 2,
        notes: 'تنظيف منتظم',
      ),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage3,
      durationDays: debugMode ? 1 : 8,
      temperatureRange: const TemperatureRange(min: 24, max: 26, optimal: 25),
      humidityRange: const HumidityRange(min: 65, max: 75, optimal: 70),
      feeding: const FeedingSchedule(
        frequency: 5,
        foodType: 'أوراق التوت',
        notes: 'أقصى كمية غذاء',
      ),
      cleaning: const CleaningSchedule(
        frequency: 3,
        notes: 'تنظيف متكرر',
      ),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage4,
      durationDays: debugMode ? 1 : 8,
      temperatureRange: const TemperatureRange(min: 24, max: 26, optimal: 25),
      humidityRange: const HumidityRange(min: 60, max: 70, optimal: 65),
      feeding: const FeedingSchedule(
        frequency: 5,
        foodType: 'أوراق التوت الناضجة',
        notes: 'المرحلة النهائية قبل التشرنق',
      ),
      cleaning: const CleaningSchedule(
        frequency: 3,
        notes: 'نظافة عالية',
      ),
    ),
    StageConfig(
      stage: IncubationStage.larvaStage5,
      durationDays: debugMode ? 1 : 10,
      temperatureRange: const TemperatureRange(min: 24, max: 26, optimal: 25),
      humidityRange: const HumidityRange(min: 60, max: 70, optimal: 65),
      feeding: const FeedingSchedule(
        frequency: 0,
        foodType: 'لا يوجد',
        notes: 'لا تغذية في مرحلة الشرنقة',
      ),
      cleaning: const CleaningSchedule(
        frequency: 1,
        notes: 'تنظيف خفيف فقط',
      ),
    ),
  ];

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
