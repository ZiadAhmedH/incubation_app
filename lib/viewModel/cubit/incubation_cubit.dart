import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:incubation_app/services/semulation_service.dart';
import 'package:incubation_app/services/ui_ticker.dart';
import '../../models/data_model.dart';
import '../../services/firebase_service.dart';
import '../../services/local_storage_service.dart';
import '../services/stage_monitor.dart';
import '../services/device_control_service.dart';
import 'incubation_state.dart';

class IncubationCubit extends Cubit<IncubationState> {
  final SimulationService _simulationService = SimulationService();
  final FirebaseService _firebaseService = FirebaseService();
  final LocalStorageService _localStorage = LocalStorageService();

  // collaborators
  final UiTicker _uiTicker = UiTicker();
  late final StageMonitor _stageMonitor;
  late final DeviceControlService _deviceControlService;

  String? _userId;
  String? _unitId;
  UserData? _currentUser;

  IncubationCubit() : super(const IncubationInitial()) {
    _stageMonitor = StageMonitor(
      _simulationService,
      _firebaseService,
      _localStorage,
    );
    _deviceControlService = DeviceControlService(
      _firebaseService,
      _simulationService,
    );
    _initialize();
  }

  void _startUiTicker() {
    _uiTicker.start(() {
      if (state is IncubationRunning)
        emit((state as IncubationRunning).copyWith());
    });
  }

  void _stopUiTicker() => _uiTicker.stop();

  Future<void> _initialize() async {
    try {
      // التحقق من التسجيل المحلي
      final isRegistered = await _localStorage.isUserRegistered();

      if (isRegistered) {
        final userData = await _localStorage.getUserData();

        if (userData != null) {
          _currentUser = userData;
          _userId = userData.userName;
          _unitId = userData.unitName;

          // محاولة استرجاع الدورة من Firebase
          try {
            final cycle = await _firebaseService.getCurrentCycle(
              _userId!,
              _simulationService.stageConfigs,
            );

            if (cycle != null && cycle.isActive) {
              emit(IncubationRunning(cycle: cycle, userData: userData));
              _startUiTicker(); // <-- ensure UI updates start
              _startSimulation(cycle);
              _stageMonitor.start(
                cycle,
                _checkStageTransition,
              ); // delegate monitoring
              _listenToDeviceControl();
              return;
            }
          } catch (e) {
            print('خطأ في استرجاع الدورة من Firebase: $e');
          }

          // إذا لم توجد دورة نشطة، انتقل لـ IncubationRegistered
          emit(IncubationRegistered(userData: userData));
          return;
        }
      }

      // المستخدم غير مسجل
      emit(const IncubationNoCycle());
    } catch (e) {
      print('خطأ في التهيئة: $e');
      emit(const IncubationNoCycle());
    }
  }

  Future<void> registerUser(
    String userName,
    String unitName,
    int eggCount,
  ) async {
    try {
      final userData = UserData(
        userName: userName,
        unitName: unitName,
        eggCount: eggCount,
        registrationDate: DateTime.now(),
      );

      // حفظ محلياً
      await _localStorage.saveUserData(userData);

      // حفظ في Firebase
      _userId = userName;
      _unitId = unitName;
      _currentUser = userData;

      try {
        await _firebaseService.saveUserData(_userId!, userData);
      } catch (e) {
        print('خطأ في حفظ البيانات في Firebase: $e');
        // استمر حتى لو فشل Firebase (يعمل محلياً)
      }

      emit(IncubationRegistered(userData: userData));
    } catch (e) {
      emit(IncubationError(message: 'فشل في التسجيل: ${e.toString()}'));
    }
  }

  void _listenToDeviceControl() {
    if (_unitId != null) _deviceControlService.start(_unitId!);
  }

  Future<void> startNewCycle() async {
    if (_userId == null || _currentUser == null) {
      emit(const IncubationError(message: 'يجب التسجيل أولاً'));
      return;
    }
    try {
      final now = DateTime.now();
      final cycle = IncubationCycle(
        id: 'cycle-${now.millisecondsSinceEpoch}',
        startDate: now,
        currentStage: IncubationStage.eggIncubation,
        stageStartDate: now,
        totalDuration: 44,
        stages: _simulationService.stageConfigs,
        isActive: true,
      );

      // حفظ في Firebase
      try {
        await _firebaseService.saveIncubationCycle(_userId!, cycle);
      } catch (e) {
        print('خطأ في حفظ الدورة في Firebase: $e');
      }

      // حفظ محلياً
      await _localStorage.saveCycleId(cycle.id);
      await _localStorage.saveCurrentStage(cycle.currentStage);

      emit(IncubationRunning(cycle: cycle, userData: _currentUser!));
      _startUiTicker();
      _startSimulation(cycle);
      _stageMonitor.start(cycle, _checkStageTransition); // delegate monitoring
      if (_unitId != null) _deviceControlService.start(_unitId!);
    } catch (e) {
      emit(IncubationError(message: 'فشل في بدء الدورة: ${e.toString()}'));
    }
  }

  void _startSimulation(IncubationCycle cycle) {
    _simulationService.startSimulation(
      currentStage: cycle.currentStage,
      onDataUpdate: (sensorData) async {
        if (state is IncubationRunning) {
          final currentState = state as IncubationRunning;
          final updatedHistory = List<SensorData>.from(
            currentState.sensorHistory,
          );
          updatedHistory.add(sensorData);

          if (updatedHistory.length > 100) {
            updatedHistory.removeAt(0);
          }

          if (_unitId != null) {
            try {
              await _firebaseService.saveSensorData(_unitId!, sensorData);
              await _firebaseService.saveReadingHistory(_unitId!, sensorData);

              if (updatedHistory.length % 50 == 0) {
                await _firebaseService.cleanOldReadings(_unitId!);
              }
            } catch (e) {
              print('خطأ في حفظ البيانات في Firebase: $e');
            }
          }

          emit(
            IncubationRunning(
              cycle: currentState.cycle,
              userData: currentState.userData,
              latestSensorData: sensorData,
              sensorHistory: updatedHistory,
            ),
          );
        }
      },
    );
  }

  Future<void> _checkStageTransition() async {
    if (state is! IncubationRunning) return;
    final currentState = state as IncubationRunning;
    final cycle = currentState.cycle;
    if (!cycle.isActive) return;

    if (!_stageMonitor.shouldTransition(cycle)) return;

    // perform transition (same logic) but use _stageMonitor.persistStageChange for persistence
    final currentIndex = cycle.currentStage.order;
    final allStages = IncubationStage.values;

    if (currentIndex < allStages.length - 1) {
      final oldStage = cycle.currentStage;
      final newStage = allStages[currentIndex + 1];

      final updatedCycle = cycle.copyWith(
        currentStage: newStage,
        stageStartDate: DateTime.now(),
      );

      try {
        if (_userId != null) {
          await _firebaseService.saveIncubationCycle(_userId!, updatedCycle);
          await _firebaseService.saveStageTransition(
            _userId!,
            oldStage,
            newStage,
          );
        }

        await _localStorage.saveCurrentStage(newStage);
      } catch (e) {
        print('خطأ في حفظ تغيير المرحلة: $e');
      }

      emit(
        IncubationStageChanged(
          cycle: updatedCycle,
          userData: currentState.userData,
          newStage: newStage,
          latestSensorData: currentState.latestSensorData,
          sensorHistory: currentState.sensorHistory,
        ),
      );

      _simulationService.stopSimulation();
      _startSimulation(updatedCycle);

      Future.delayed(const Duration(seconds: 2), () {
        if (state is IncubationStageChanged) {
          final stageChangedState = state as IncubationStageChanged;
          emit(
            IncubationRunning(
              cycle: stageChangedState.cycle,
              userData: stageChangedState.userData,
              latestSensorData: stageChangedState.latestSensorData,
              sensorHistory: stageChangedState.sensorHistory,
            ),
          );
          _startUiTicker(); // <-- restart UI ticker after transition
        }
      });
    } else {
      final completedCycle = cycle.copyWith(isActive: false);

      try {
        if (_userId != null) {
          await _firebaseService.saveIncubationCycle(_userId!, completedCycle);
        }
      } catch (e) {
        print('خطأ في حفظ إكمال الدورة: $e');
      }

      emit(
        IncubationCompleted(
          cycle: completedCycle,
          userData: currentState.userData,
        ),
      );
      stopCycle();
    }
  }

  Future<void> updateDeviceControl({
    required bool fan,
    required bool heater,
  }) async {
    if (_unitId == null) return;

    try {
      await _firebaseService.updateDeviceControl(_unitId!, fan, heater);
      _simulationService.updateDeviceControl(fan: fan, heater: heater);
    } catch (e) {
      print('خطأ في تحديث التحكم: $e');
      // استمر مع المحاكاة حتى لو فشل Firebase
      _simulationService.updateDeviceControl(fan: fan, heater: heater);
    }
  }

  Future<void> stopCycle() async {
    _simulationService.stopSimulation();
    _stageMonitor.stop();
    _deviceControlService.stop();
    _stopUiTicker();

    if (state is IncubationRunning) {
      final currentState = state as IncubationRunning;
      final stoppedCycle = currentState.cycle.copyWith(isActive: false);

      try {
        if (_userId != null) {
          await _firebaseService.saveIncubationCycle(_userId!, stoppedCycle);
        }
      } catch (e) {
        print('خطأ في حفظ إيقاف الدورة: $e');
      }

      emit(
        IncubationRunning(
          cycle: stoppedCycle,
          userData: currentState.userData,
          latestSensorData: currentState.latestSensorData,
          sensorHistory: currentState.sensorHistory,
        ),
      );
    }
  }

  StageConfig? getCurrentStageConfig() {
    if (state is IncubationRunning) {
      final currentState = state as IncubationRunning;
      return currentState.cycle.stages.firstWhere(
        (s) => s.stage == currentState.cycle.currentStage,
      );
    }
    return null;
  }

  bool isTemperatureInRange() {
    if (state is! IncubationRunning) return true;

    final currentState = state as IncubationRunning;
    if (currentState.latestSensorData == null) return true;

    final config = getCurrentStageConfig();
    if (config == null) return true;

    return currentState.latestSensorData!.temperature >=
            config.temperatureRange.min &&
        currentState.latestSensorData!.temperature <=
            config.temperatureRange.max;
  }

  bool isHumidityInRange() {
    if (state is! IncubationRunning) return true;

    final currentState = state as IncubationRunning;
    if (currentState.latestSensorData == null) return true;

    final config = getCurrentStageConfig();
    if (config == null) return true;

    return currentState.latestSensorData!.humidity >=
            config.humidityRange.min &&
        currentState.latestSensorData!.humidity <= config.humidityRange.max;
  }

  UserData? get currentUser => _currentUser;

  // دالة للفحص اليدوي
  void checkStageTransitionManually() {
    _checkStageTransition();
  }

  // دالة للقفز المباشر (للتطوير فقط)
  Future<void> skipToNextStage() async {
    if (state is! IncubationRunning) return;

    final currentState = state as IncubationRunning;
    await _transitionToNextStage(currentState);
  }

  Future<void> _transitionToNextStage(IncubationRunning currentState) async {
    final cycle = currentState.cycle;
    final currentIndex = cycle.currentStage.order;
    final allStages = IncubationStage.values;

    if (currentIndex < allStages.length - 1) {
      final oldStage = cycle.currentStage;
      final newStage = allStages[currentIndex + 1];

      final updatedCycle = cycle.copyWith(
        currentStage: newStage,
        stageStartDate: DateTime.now(),
      );

      try {
        if (_userId != null) {
          await _firebaseService.saveIncubationCycle(_userId!, updatedCycle);
          await _firebaseService.saveStageTransition(
            _userId!,
            oldStage,
            newStage,
          );
        }
        await _localStorage.saveCurrentStage(newStage);
      } catch (e) {
        print('خطأ في حفظ تغيير المرحلة: $e');
      }

      emit(
        IncubationStageChanged(
          cycle: updatedCycle,
          userData: currentState.userData,
          newStage: newStage,
          latestSensorData: currentState.latestSensorData,
          sensorHistory: currentState.sensorHistory,
        ),
      );

      _simulationService.stopSimulation();
      _startSimulation(updatedCycle);

      Future.delayed(const Duration(seconds: 2), () {
        if (state is IncubationStageChanged) {
          final stageChangedState = state as IncubationStageChanged;
          emit(
            IncubationRunning(
              cycle: stageChangedState.cycle,
              userData: stageChangedState.userData,
              latestSensorData: stageChangedState.latestSensorData,
              sensorHistory: stageChangedState.sensorHistory,
            ),
          );
          _startUiTicker(); // restart UI ticker after transition
        }
      });
    } else {
      final completedCycle = cycle.copyWith(isActive: false);

      try {
        if (_userId != null) {
          await _firebaseService.saveIncubationCycle(_userId!, completedCycle);
        }
      } catch (e) {
        print('خطأ في حفظ إكمال الدورة: $e');
      }

      emit(
        IncubationCompleted(
          cycle: completedCycle,
          userData: currentState.userData,
        ),
      );
      stopCycle();
    }
  }

  @override
  Future<void> close() {
    _uiTicker.stop();
    _stageMonitor.dispose();
    _deviceControlService.dispose();
    return super.close();
  }
}
