import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:incubation_app/services/oneSignal_serveice.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/data_sources/remote/firebase_service.dart';
import '../../data/data_sources/local/local_storage_service.dart';
import '../../data/models/data_model.dart';
import '../../data/repositories/incubation_repository.dart';
import '../../domain/usecases/cycle/start_cycle_use_case.dart';
import '../../domain/usecases/cycle/stop_cycle_use_case.dart';
import '../../domain/usecases/cycle/transition_stage_use_case.dart';
import '../../domain/usecases/device/update_device_control.dart';
import '../../domain/usecases/user/register_user_use_case.dart';
import '../../services/feading_scheduale_service.dart';
import '../../services/semulation_service.dart';
import '../../services/ui_ticker.dart';
import '../viewModel/services/stage_monitor.dart';
import '../viewModel/services/device_control_service.dart';
import 'incubation_state.dart';

class IncubationCubit extends Cubit<IncubationState> {
  final IncubationRepository _repository;
  final FirebaseService _firebase;
  final LocalStorageService _localStorage;
  final SimulationService _simulation;
  final RegisterUserUseCase _registerUser;
  final StartCycleUseCase _startCycle;
  final TransitionStageUseCase _transitionStage;
  final StopCycleUseCase _stopCycle;
  final UpdateDeviceControlUseCase _updateDeviceControl;

  final UiTicker _uiTicker = UiTicker();
  late final StageMonitor _stageMonitor;
  late final DeviceControlService _deviceControl;
  final FeedingScheduleService _feedingSchedule = FeedingScheduleService();

  String? _userId;
  String? _unitId;
  UserData? _currentUser;

  IncubationCubit(
    this._repository,
    this._firebase,
    this._localStorage,
    this._simulation,
    this._registerUser,
    this._startCycle,
    this._transitionStage,
    this._stopCycle,
    this._updateDeviceControl,
  ) : super(const IncubationInitial()) {
    _stageMonitor = StageMonitor(_simulation, _firebase, _localStorage);
    _deviceControl = DeviceControlService(_firebase, _simulation);
    _initialize();
  }

  void _startUiTicker() {
    _uiTicker.start(() {
      if (state is IncubationRunning) {
        emit((state as IncubationRunning).copyWith());
      }
    });
  }

  Future<void> _initialize() async {
    try {
      if (!await _repository.isUserRegistered()) {
        emit(const IncubationNoCycle());
        return;
      }

      final user = await _repository.getUserData();
      if (user == null) {
        emit(const IncubationNoCycle());
        return;
      }

      _currentUser = user;
      _userId = user.userName;
      _unitId = user.unitName;

      // ✅ ربط OneSignal بالمستخدم
      await OneSignalService.setExternalUserId(user.userName);

      final cycle = await _repository.getCurrentCycle(
        _userId!,
        _simulation.stageConfigs,
      );

      if (cycle != null && cycle.isActive) {
        // ✅ تحديث Tags في OneSignal
        await OneSignalService.setUserTags(
          stage: cycle.currentStage.name,
          dayInCycle: cycle.currentStageDaysRemaining,
          unitId: _unitId ?? 'unknown',
        );

        emit(IncubationRunning(cycle: cycle, userData: user));
        _startUiTicker();
        _startSimulation(cycle);
        _stageMonitor.start(cycle, _onStageTransition);
        _deviceControl.start(_unitId!);

        await _saveCycleToPrefs(cycle);
      } else {
        emit(IncubationRegistered(userData: user));
      }
    } catch (e) {
      print('❌ خطأ في التهيئة: $e');
      emit(const IncubationNoCycle());
    }
  }

  Future<void> registerUser(String name, String unit, int eggs) async {
    try {
      final user = await _registerUser(name, unit, eggs);
      _userId = name;
      _unitId = unit;
      _currentUser = user;

      // ✅ ربط OneSignal بالمستخدم
      await OneSignalService.setExternalUserId(name);

      // ✅ إضافة Tags أولية
      await OneSignalService.setUserTags(
        stage: 'not_started',
        dayInCycle: 0,
        unitId: unit,
      );

      emit(IncubationRegistered(userData: user));
    } catch (e) {
      emit(IncubationError(message: 'فشل التسجيل: $e'));
    }
  }

  Future<void> startNewCycle() async {
    if (_userId == null || _currentUser == null) {
      emit(const IncubationError(message: 'يجب التسجيل أولاً'));
      return;
    }

    try {
      final cycle = await _startCycle(_currentUser!);

      // ✅ تحديث Tags في OneSignal
      await OneSignalService.setUserTags(
        stage: cycle.currentStage.name,
        dayInCycle: cycle.currentStageDaysRemaining,
        unitId: _unitId ?? 'unknown',
      );

      // ✅ إرسال إشعار بدء الدورة
      if (_userId != null) {
        await OneSignalService.sendNotificationToUser(
          userId: _userId!,
          title: '🎉 بدء دورة جديدة',
          message: 'تم بدء دورة حضانة جديدة\n'
              'المرحلة الأولى: ${cycle.currentStage.arabicName}',
          data: {
            'type': 'cycle_start',
            'stage': cycle.currentStage.name,
          },
        );
      }

      // ✅ حفظ معلومات المرحلة في Firebase
      await _saveStageInfoToFirebase(cycle);

      emit(IncubationRunning(cycle: cycle, userData: _currentUser!));
      _startUiTicker();
      _startSimulation(cycle);
      _stageMonitor.start(cycle, _onStageTransition);
      if (_unitId != null) _deviceControl.start(_unitId!);

      await _saveCycleToPrefs(cycle);
    } catch (e) {
      emit(IncubationError(message: 'فشل بدء الدورة: $e'));
    }
  }

  void _startSimulation(IncubationCycle cycle) {
    _simulation.startSimulation(
      currentStage: cycle.currentStage,
      onDataUpdate: _onSensorUpdate,
    );
  }

  Future<void> _onSensorUpdate(SensorData data) async {
    if (state is! IncubationRunning) return;

    final current = state as IncubationRunning;
    final history = List<SensorData>.from(current.sensorHistory)..add(data);
    if (history.length > 100) history.removeAt(0);

    if (_unitId != null) {
      await _repository.saveSensorData(_unitId!, data);
      if (history.length % 50 == 0) {
        await _repository.cleanOldReadings(_unitId!);
      }
    }

    emit(current.copyWith(
      latestSensorData: data,
      sensorHistory: history,
    ));
  }

  // ✅ إرسال إشعار عند تغيير المرحلة
  Future<void> _onStageTransition() async {
    if (state is! IncubationRunning) return;

    final current = state as IncubationRunning;
    if (!_stageMonitor.shouldTransition(current.cycle)) return;

    final oldStage = current.cycle.currentStage; // ✅ حفظ المرحلة القديمة

    final updated = await _transitionStage(_userId!, current.cycle);
    if (updated == null) return;

    // ✅ تحديث Tags عند تغيير المرحلة
    await OneSignalService.setUserTags(
      stage: updated.currentStage.name,
      dayInCycle: updated.currentStageDaysRemaining,
      unitId: _unitId ?? 'unknown',
    );

    // ✅ إرسال إشعار تغيير المرحلة
    if (_userId != null) {
      await OneSignalService.sendStageChangeNotification(
        userId: _userId!,
        oldStage: oldStage,
        newStage: updated.currentStage,
      );
    }

    // ✅ حفظ معلومات المرحلة الجديدة
    await _saveStageInfoToFirebase(updated);

    // ✅ إعادة تعيين عداد التغذية عند تغيير المرحلة
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('feeding_count_today', 0);

    if (updated.isActive) {
      emit(IncubationStageChanged(
        cycle: updated,
        userData: current.userData,
        newStage: updated.currentStage,
        latestSensorData: current.latestSensorData,
        sensorHistory: current.sensorHistory,
      ));

      _simulation.stopSimulation();
      _startSimulation(updated);

      await Future.delayed(const Duration(seconds: 2));
      if (state is IncubationStageChanged) {
        final changed = state as IncubationStageChanged;
        emit(IncubationRunning(
          cycle: changed.cycle,
          userData: changed.userData,
          latestSensorData: changed.latestSensorData,
          sensorHistory: changed.sensorHistory,
        ));
        _startUiTicker();
      }
    } else {
      // ✅ إشعار انتهاء الدورة
      if (_userId != null) {
        await OneSignalService.sendNotificationToUser(
          userId: _userId!,
          title: '🎊 اكتملت دورة الحضانة',
          message: 'تهانينا! اكتملت دورة حضانة دودة القز بنجاح',
          data: {
            'type': 'cycle_complete',
          },
        );
      }

      emit(IncubationCompleted(cycle: updated, userData: current.userData));
      await stopCycle();
    }
  }

  Future<void> updateDeviceControl({
    required bool fan,
    required bool heater,
  }) async {
    if (_unitId == null) return;
    try {
      await _updateDeviceControl(_unitId!, fan, heater);
    } catch (e) {
      print('❌ خطأ في تحديث التحكم: $e');
    }
  }

  Future<void> stopCycle() async {
    if (_userId == null || state is! IncubationRunning) return;

    final current = state as IncubationRunning;
    final stopped = await _stopCycle(_userId!, current.cycle);

    _simulation.stopSimulation();
    _stageMonitor.stop();
    _deviceControl.stop();
    _uiTicker.stop();
    _feedingSchedule.stopFeedingSchedule();

    // ✅ إزالة Tags من OneSignal
    await OneSignalService.setUserTags(
      stage: 'stopped',
      dayInCycle: 0,
      unitId: _unitId ?? 'unknown',
    );

    emit(current.copyWith(cycle: stopped));
  }

  Future<void> _saveStageInfoToFirebase(IncubationCycle cycle) async {
    if (_userId == null) return;

    try {
      await _firebase.saveSensorData(
          'users/$_userId/current_stage',
          {
            'stage': cycle.currentStage.name,
            'stage_arabic': cycle.currentStage.arabicName,
            'day_in_cycle': cycle.currentStageDaysRemaining,
            'days_remaining': cycle.currentStageDaysRemaining,
            'feeding_percent':
                OneSignalService.getFeedingPercentage(cycle.currentStage),
            'updated_at': DateTime.now().toIso8601String(),
          } as SensorData);

      print('✅ تم حفظ معلومات المرحلة في Firebase');
    } catch (e) {
      print('❌ خطأ في حفظ معلومات المرحلة: $e');
    }
  }

  // Helper methods
  StageConfig? getCurrentStageConfig() {
    if (state is! IncubationRunning) return null;
    final current = state as IncubationRunning;
    return current.cycle.stages.firstWhere(
      (s) => s.stage == current.cycle.currentStage,
      orElse: () => StageConfig(
        stage: current.cycle.currentStage,
        durationDays: 0,
        temperatureRange: const TemperatureRange(min: 20, max: 30, optimal: 25),
        humidityRange: const HumidityRange(min: 50, max: 80, optimal: 65),
      ),
    );
  }

  bool isTemperatureInRange() {
    if (state is! IncubationRunning) return true;
    final s = state as IncubationRunning;
    if (s.latestSensorData == null) return true;
    final cfg = getCurrentStageConfig();
    if (cfg == null) return true;
    return s.latestSensorData!.temperature >= cfg.temperatureRange.min &&
        s.latestSensorData!.temperature <= cfg.temperatureRange.max;
  }

  bool isHumidityInRange() {
    if (state is! IncubationRunning) return true;
    final s = state as IncubationRunning;
    if (s.latestSensorData == null) return true;
    final cfg = getCurrentStageConfig();
    if (cfg == null) return true;
    return s.latestSensorData!.humidity >= cfg.humidityRange.min &&
        s.latestSensorData!.humidity <= cfg.humidityRange.max;
  }

  UserData? get currentUser => _currentUser;
  FeedingScheduleService get feedingSchedule => _feedingSchedule;

  void checkStageTransitionManually() => _onStageTransition();

  Future<void> skipToNextStage() async {
    if (state is! IncubationRunning) return;
    await _onStageTransition();
  }

  Future<void> _saveCycleToPrefs(IncubationCycle cycle) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cycle_active', cycle.isActive);
    await prefs.setString(
        'cycle_start_date', cycle.startDate.toIso8601String());
    await prefs.setString(
        'stage_start_date', cycle.stageStartDate.toIso8601String());
    await prefs.setInt('current_stage', cycle.currentStage.order);

    final currentDay =
        '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    await prefs.setString('last_feeding_day', currentDay);
    await prefs.setInt('feeding_count_today', 0);
  }

  @override
  Future<void> close() {
    _uiTicker.stop();
    _stageMonitor.dispose();
    _deviceControl.dispose();
    _feedingSchedule.dispose();
    return super.close();
  }
}
