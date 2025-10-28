import 'package:incubation_app/models/data_model.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LocalStorageService {
  static const String _keyUserData = 'user_data';
  static const String _keyCycleId = 'current_cycle_id';
  static const String _keyCurrentStage = 'current_stage';
  static const String _keyIsRegistered = 'is_registered';

  Future<void> saveUserData(UserData userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, userDataToJson(userData));
    await prefs.setBool(_keyIsRegistered, true);
  }

  Future<UserData?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyUserData);
    if (jsonString != null) {
      return userDataFromJson(jsonString);
    }
    return null;
  }

  Future<bool> isUserRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsRegistered) ?? false;
  }

  Future<void> saveCycleId(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCycleId, cycleId);
  }

  Future<String?> getCycleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCycleId);
  }

  Future<void> saveCurrentStage(IncubationStage stage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentStage, stage.name);
  }

  Future<IncubationStage?> getCurrentStage() async {
    final prefs = await SharedPreferences.getInstance();
    final stageName = prefs.getString(_keyCurrentStage);
    if (stageName != null) {
      return IncubationStage.values.firstWhere(
        (e) => e.name == stageName,
        orElse: () => IncubationStage.eggIncubation,
      );
    }
    return null;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  String userDataToJson(UserData data) {
    return '${data.userName}|||${data.unitName}|||${data.eggCount}|||${data.registrationDate?.toIso8601String() ?? ''}';
  }

  UserData userDataFromJson(String json) {
    final parts = json.split('|||');
    return UserData(
      userName: parts[0],
      unitName: parts[1],
      eggCount: int.parse(parts[2]),
      registrationDate: parts[3].isNotEmpty ? DateTime.parse(parts[3]) : null,
    );
  }
}
