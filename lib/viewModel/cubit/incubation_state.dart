import 'package:equatable/equatable.dart';
import 'package:incubation_app/models/data_model.dart';


abstract class IncubationState extends Equatable {
  const IncubationState();

  @override
  List<Object?> get props => [];
}

class IncubationInitial extends IncubationState {
  const IncubationInitial();
}

class IncubationNoCycle extends IncubationState {
  const IncubationNoCycle();
}

class IncubationRegistered extends IncubationState {
  final UserData userData;

  const IncubationRegistered({required this.userData});

  @override
  List<Object?> get props => [userData];
}

class IncubationRunning extends IncubationState {
  final IncubationCycle cycle;
  final UserData userData;
  final SensorData? latestSensorData;
  final List<SensorData> sensorHistory;

  const IncubationRunning({
    required this.cycle,
    required this.userData,
    this.latestSensorData,
    this.sensorHistory = const [],
  });

  IncubationRunning copyWith({
    IncubationCycle? cycle,
    UserData? userData,
    SensorData? latestSensorData,
    List<SensorData>? sensorHistory,
  }) {
    return IncubationRunning(
      cycle: cycle ?? this.cycle,
      userData: userData ?? this.userData,
      latestSensorData: latestSensorData ?? this.latestSensorData,
      sensorHistory: sensorHistory ?? this.sensorHistory,
    );
  }

  @override
  List<Object?> get props => [cycle, userData, latestSensorData, sensorHistory];
}

class IncubationStageChanged extends IncubationState {
  final IncubationCycle cycle;
  final UserData userData;
  final IncubationStage newStage;
  final SensorData? latestSensorData;
  final List<SensorData> sensorHistory;

  const IncubationStageChanged({
    required this.cycle,
    required this.userData,
    required this.newStage,
    this.latestSensorData,
    this.sensorHistory = const [],
  });

  @override
  List<Object?> get props => [
    cycle,
    userData,
    newStage,
    latestSensorData,
    sensorHistory,
  ];
}

class IncubationCompleted extends IncubationState {
  final IncubationCycle cycle;
  final UserData userData;

  const IncubationCompleted({required this.cycle, required this.userData});

  @override
  List<Object?> get props => [cycle, userData];
}

class IncubationError extends IncubationState {
  final String message;

  const IncubationError({required this.message});

  @override
  List<Object?> get props => [message];
}
