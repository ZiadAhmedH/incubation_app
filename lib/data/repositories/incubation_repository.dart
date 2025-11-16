import '../data_sources/local/local_storage_service.dart';
import '../data_sources/remote/firebase_service.dart';
import '../models/data_model.dart';

class IncubationRepository {
  final FirebaseService _firebase;
  final LocalStorageService _localStorage;

  IncubationRepository(this._firebase, this._localStorage);

  FirebaseService get firebaseService => _firebase;

  // User operations
  Future<bool> isUserRegistered() => _localStorage.isUserRegistered();

  Future<UserData?> getUserData() => _localStorage.getUserData();

  Future<void> saveUser(UserData user) async {
    await _localStorage.saveUserData(user);
    try {
      await _firebase.saveUserData(user.userName, user);
    } catch (e) {
      print('Firebase save user failed: $e');
    }
  }

  // Cycle operations
  Future<IncubationCycle?> getCurrentCycle(
    String userId,
    List<StageConfig> configs,
  ) async {
    try {
      return await _firebase.getCurrentCycle(userId, configs);
    } catch (e) {
      print('Firebase get cycle failed: $e');
      return null;
    }
  }

  Future<void> saveCycle(String userId, IncubationCycle cycle) async {
    await _localStorage.saveCycleId(cycle.id);
    await _localStorage.saveCurrentStage(cycle.currentStage);
    try {
      await _firebase.saveIncubationCycle(userId, cycle);
    } catch (e) {
      print('Firebase save cycle failed: $e');
    }
  }

  Future<void> saveStageTransition(
    String userId,
    IncubationStage from,
    IncubationStage to,
  ) async {
    await _localStorage.saveCurrentStage(to);
    try {
      await _firebase.saveStageTransition(userId, from, to);
    } catch (e) {
      print('Firebase save transition failed: $e');
    }
  }

  // Sensor operations
  Future<void> saveSensorData(String unitId, SensorData data) async {
    try {
      await _firebase.saveSensorData(unitId, data);
      await _firebase.saveReadingHistory(unitId, data);
    } catch (e) {
      print('Firebase save sensor failed: $e');
    }
  }

  Future<void> cleanOldReadings(String unitId) async {
    try {
      await _firebase.cleanOldReadings(unitId);
    } catch (e) {
      print('Firebase clean readings failed: $e');
    }
  }

  Future<void> updateDeviceControl(String unitId, bool fan, bool heater) async {
    try {
      await _firebase.updateDeviceControl(unitId, fan, heater);
    } catch (e) {
      print('Firebase update control failed: $e');
    }
  }

  Stream<Map<String, dynamic>?> watchDeviceControl(String unitId) =>
      _firebase.watchDeviceControl(unitId);
}
