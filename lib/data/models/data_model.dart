import 'package:equatable/equatable.dart';
import 'package:incubation_app/services/semulation_service.dart';

enum IncubationStage {
  eggIncubation('حضانة البيض', 0),
  larvaStage1('يرقة - المرحلة 1', 1),
  larvaStage2('يرقة - المرحلة 2', 2),
  larvaStage3('يرقة - المرحلة 3', 3),
  larvaStage4('يرقة - المرحلة 4', 4),
  larvaStage5('يرقة - المرحلة 5', 5),
  pupa('العذراء (التشرنق)', 6);

  final String arabicName;
  final int order;
  const IncubationStage(this.arabicName, this.order);
}

class SensorData extends Equatable {
  final double temperature;
  final double humidity;
  final bool fanOn;
  final bool heaterOn;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.fanOn,
    required this.heaterOn,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      fanOn: json['fan'] as bool? ?? false,
      heaterOn: json['heater'] as bool? ?? false,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'fan': fanOn,
      'heater': heaterOn,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  SensorData copyWith({
    double? temperature,
    double? humidity,
    bool? fanOn,
    bool? heaterOn,
    DateTime? timestamp,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      fanOn: fanOn ?? this.fanOn,
      heaterOn: heaterOn ?? this.heaterOn,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
    temperature,
    humidity,
    fanOn,
    heaterOn,
    timestamp,
  ];
}

class TemperatureRange extends Equatable {
  final double min;
  final double max;
  final double optimal;

  const TemperatureRange({
    required this.min,
    required this.max,
    required this.optimal,
  });

  @override
  List<Object?> get props => [min, max, optimal];
}

class HumidityRange extends Equatable {
  final double min;
  final double max;
  final double optimal;

  const HumidityRange({
    required this.min,
    required this.max,
    required this.optimal,
  });

  @override
  List<Object?> get props => [min, max, optimal];
}

class FeedingInfo extends Equatable {
  final int frequency;
  final String notes;

  const FeedingInfo({required this.frequency, required this.notes});

  Map<String, dynamic> toJson() => {'frequency': frequency, 'notes': notes};

  @override
  List<Object?> get props => [frequency, notes];
}

class CleaningInfo extends Equatable {
  final int frequency;
  final String notes;

  const CleaningInfo({required this.frequency, required this.notes});

  Map<String, dynamic> toJson() => {'frequency': frequency, 'notes': notes};

  @override
  List<Object?> get props => [frequency, notes];
}

class StageConfig extends Equatable {
  final IncubationStage stage;
  final int durationDays;
  final TemperatureRange temperatureRange;
  final HumidityRange humidityRange;
  final FeedingSchedule? feeding; // إضافة
  final CleaningSchedule? cleaning; // إضافة

  const StageConfig({
    required this.stage,
    required this.durationDays,
    required this.temperatureRange,
    required this.humidityRange,
    this.feeding,
    this.cleaning,
  });

  @override
  List<Object?> get props => [
    stage,
    durationDays,
    temperatureRange,
    humidityRange,
    feeding,
    cleaning,
  ];
}

class FeedingSchedule extends Equatable {
  final int frequency; // عدد المرات في اليوم
  final String foodType; // نوع الطعام
  final String notes; // ملاحظات

  const FeedingSchedule({
    required this.frequency,
    required this.foodType,
    required this.notes,
  });

  @override
  List<Object?> get props => [frequency, foodType, notes];
}

class CleaningSchedule extends Equatable {
  final int frequency; // عدد المرات في اليوم
  final String notes; // ملاحظات

  const CleaningSchedule({required this.frequency, required this.notes});

  @override
  List<Object?> get props => [frequency, notes];
}

class IncubationCycle extends Equatable {
  final String id;
  final DateTime startDate;
  final IncubationStage currentStage;
  final DateTime stageStartDate;
  final int totalDuration;
  final List<StageConfig> stages;
  final bool isActive;

  const IncubationCycle({
    required this.id,
    required this.startDate,
    required this.currentStage,
    required this.stageStartDate,
    required this.totalDuration,
    required this.stages,
    this.isActive = true,
  });

  int get daysRemaining {
    final totalDays = stages.fold<int>(
      0,
      (sum, config) => sum + config.durationDays,
    );

    // في وضع Debug: استخدم الدقائق
    final timePassed = DateTime.now().difference(startDate);
    final unitsPassed = SimulationService.debugMode
        ? timePassed.inMinutes
        : timePassed.inDays;

    return (totalDays - unitsPassed).clamp(0, totalDays);
  }

  int get currentStageDaysRemaining {
    final currentConfig = stages.firstWhere((s) => s.stage == currentStage);

    // في وضع Debug: استخدم الدقائق
    final timePassed = DateTime.now().difference(stageStartDate);
    final unitsPassed = SimulationService.debugMode
        ? timePassed.inMinutes
        : timePassed.inDays;

    return (currentConfig.durationDays - unitsPassed).clamp(
      0,
      currentConfig.durationDays,
    );
  }

  double get progress {
    final totalDays = stages.fold<int>(
      0,
      (sum, config) => sum + config.durationDays,
    );

    if (totalDays == 0) return 0;

    // في وضع Debug: استخدم الدقائق
    final timePassed = DateTime.now().difference(startDate);
    final unitsPassed = SimulationService.debugMode
        ? timePassed.inMinutes
        : timePassed.inDays;

    final calculatedProgress = (unitsPassed / totalDays * 100);
    print('📊 Progress Calculation:');
    print(
      '  Total: $totalDays ${SimulationService.debugMode ? "minutes" : "days"}',
    );
    print(
      '  Passed: $unitsPassed ${SimulationService.debugMode ? "minutes" : "days"}',
    );
    print('  Progress: ${calculatedProgress.toStringAsFixed(2)}%');

    return calculatedProgress.clamp(0, 100);
  }

  // حساب التقدم في المرحلة الحالية
  double get currentStageProgress {
    final currentConfig = stages.firstWhere((s) => s.stage == currentStage);

    if (currentConfig.durationDays == 0) return 0;

    final timePassed = DateTime.now().difference(stageStartDate);
    final unitsPassed = SimulationService.debugMode
        ? timePassed.inMinutes
        : timePassed.inDays;

    return (unitsPassed / currentConfig.durationDays * 100).clamp(0, 100);
  }

  IncubationCycle copyWith({
    String? id,
    DateTime? startDate,
    IncubationStage? currentStage,
    DateTime? stageStartDate,
    int? totalDuration,
    List<StageConfig>? stages,
    bool? isActive,
  }) {
    return IncubationCycle(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      currentStage: currentStage ?? this.currentStage,
      stageStartDate: stageStartDate ?? this.stageStartDate,
      totalDuration: totalDuration ?? this.totalDuration,
      stages: stages ?? this.stages,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    startDate,
    currentStage,
    stageStartDate,
    totalDuration,
    stages,
    isActive,
  ];
}

class UserData extends Equatable {
  final String userName;
  final String unitName;
  final int eggCount;
  final DateTime? registrationDate;

  const UserData({
    required this.userName,
    required this.unitName,
    required this.eggCount,
    this.registrationDate,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      userName: json['userName'] as String,
      unitName: json['unitName'] as String,
      eggCount: json['eggCount'] as int,
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'unitName': unitName,
      'eggCount': eggCount,
      'registrationDate': registrationDate?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [userName, unitName, eggCount, registrationDate];
}
