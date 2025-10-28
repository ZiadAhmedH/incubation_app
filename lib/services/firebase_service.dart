import 'package:firebase_database/firebase_database.dart';
import 'package:incubation_app/models/data_model.dart';


class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // حفظ بيانات المستخدم
  Future<void> saveUserData(String userId, UserData userData) async {
    try {
      await _database.child('users/$userId').set(userData.toJson());
    } catch (e) {
      throw Exception('فشل في حفظ بيانات المستخدم: $e');
    }
  }

  // استرجاع بيانات المستخدم
  Future<UserData?> getUserData(String userId) async {
    try {
      final snapshot = await _database.child('users/$userId').get();
      if (snapshot.value != null) {
        return UserData.fromJson(
          Map<String, dynamic>.from(snapshot.value as Map),
        );
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب بيانات المستخدم: $e');
    }
  }

  // حفظ بيانات الحساسات
  Future<void> saveSensorData(String unitId, SensorData data) async {
    try {
      await _database.child('units/$unitId/sensorData').set({
        'temperature': data.temperature,
        'humidity': data.humidity,
        'fan': data.fanOn,
        'heater': data.heaterOn,
        'timestamp': data.timestamp.toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل في حفظ بيانات الحساسات: $e');
    }
  }

  // حفظ سجل القراءات
  Future<void> saveReadingHistory(String unitId, SensorData data) async {
    try {
      await _database.child('units/$unitId/history').push().set({
        'temperature': data.temperature,
        'humidity': data.humidity,
        'timestamp': data.timestamp.toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل في حفظ سجل القراءات: $e');
    }
  }

  // مراقبة بيانات التحكم
  Stream<Map<String, dynamic>?> watchDeviceControl(String unitId) {
    return _database.child('units/$unitId/control').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  // تحديث التحكم في الأجهزة
  Future<void> updateDeviceControl(String unitId, bool fan, bool heater) async {
    try {
      await _database.child('units/$unitId/control').set({
        'fan': fan,
        'heater': heater,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل في تحديث التحكم: $e');
    }
  }

  // حفظ دورة الحضانة مع بيانات المستخدم
  Future<void> saveIncubationCycle(String userId, IncubationCycle cycle) async {
    try {
      await _database.child('users/$userId/currentCycle').set({
        'id': cycle.id,
        'startDate': cycle.startDate.toIso8601String(),
        'currentStage': cycle.currentStage.name,
        'stageStartDate': cycle.stageStartDate.toIso8601String(),
        'totalDuration': cycle.totalDuration,
        'isActive': cycle.isActive,
      });

      // حفظ نسخة في cycles للأرشفة
      await _database.child('cycles/${cycle.id}').set({
        'userId': userId,
        'id': cycle.id,
        'startDate': cycle.startDate.toIso8601String(),
        'currentStage': cycle.currentStage.name,
        'stageStartDate': cycle.stageStartDate.toIso8601String(),
        'totalDuration': cycle.totalDuration,
        'isActive': cycle.isActive,
      });
    } catch (e) {
      throw Exception('فشل في حفظ دورة الحضانة: $e');
    }
  }

  // استرجاع الدورة الحالية للمستخدم
  Future<IncubationCycle?> getCurrentCycle(
    String userId,
    List<StageConfig> stages,
  ) async {
    try {
      final snapshot = await _database
          .child('users/$userId/currentCycle')
          .get();
      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return IncubationCycle(
          id: data['id'],
          startDate: DateTime.parse(data['startDate']),
          currentStage: IncubationStage.values.firstWhere(
            (e) => e.name == data['currentStage'],
          ),
          stageStartDate: DateTime.parse(data['stageStartDate']),
          totalDuration: data['totalDuration'],
          stages: stages,
          isActive: data['isActive'] ?? false,
        );
      }
      return null;
    } catch (e) {
      throw Exception('فشل في جلب الدورة الحالية: $e');
    }
  }

  // حفظ سجل تغيير المراحل
  Future<void> saveStageTransition(
    String userId,
    IncubationStage fromStage,
    IncubationStage toStage,
  ) async {
    try {
      await _database.child('users/$userId/stageHistory').push().set({
        'fromStage': fromStage.name,
        'toStage': toStage.name,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('فشل في حفظ سجل تغيير المرحلة: $e');
    }
  }

  // تنظيف القراءات القديمة
  Future<void> cleanOldReadings(String unitId, {int keepLast = 100}) async {
    try {
      final snapshot = await _database
          .child('units/$unitId/history')
          .orderByKey()
          .get();

      if (snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (data.length > keepLast) {
          final entries = data.entries.toList();
          entries.sort((a, b) => a.key.compareTo(b.key));

          final toDelete = entries.take(entries.length - keepLast);
          for (var entry in toDelete) {
            await _database
                .child('units/$unitId/history/${entry.key}')
                .remove();
          }
        }
      }
    } catch (e) {
      throw Exception('فشل في تنظيف القراءات القديمة: $e');
    }
  }
}
