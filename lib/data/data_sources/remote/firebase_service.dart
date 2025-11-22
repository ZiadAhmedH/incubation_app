import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../../models/data_model.dart';

class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _sensorSubscription;

  /// Stream sensor data from Firebase
  Stream<SensorData> streamSensorData(String unitId) {
    final controller = StreamController<SensorData>();

    _sensorSubscription =
        _database.child('$unitId/sensorData').onValue.listen((event) {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;

        if (data != null) {
          final sensorData = SensorData(
            temperature: (data['temperature'] as num).toDouble(),
            humidity: (data['humidity'] as num).toDouble(),
            fanOn: data['fan'] as bool? ?? false,
            heaterOn: data['heater'] as bool? ?? false,
            timestamp: DateTime.parse(data['timestamp'] as String),
          );

          controller.add(sensorData);
        }
      } catch (e) {
        print('❌ Error parsing sensor data: $e');
        controller.addError(e);
      }
    });

    return controller.stream;
  }

  /// Get history data
  Future<List<SensorData>> getHistoryData(String unitId,
      {int limit = 100}) async {
    try {
      final snapshot = await _database
          .child('units/$unitId/history')
          .orderByKey()
          .limitToLast(limit)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) {
          final item = entry.value as Map<dynamic, dynamic>;
          return SensorData(
            temperature: (item['temperature'] as num).toDouble(),
            humidity: (item['humidity'] as num).toDouble(),
            fanOn: item['fan'] as bool? ?? false,
            heaterOn: item['heater'] as bool? ?? false,
            timestamp: DateTime.parse(item['timestamp'] as String),
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error fetching history: $e');
      return [];
    }
  }

  /// Watch device control changes
  Stream<Map<String, dynamic>?> watchDeviceControl(String unitId) {
    return _database.child('units/$unitId/control').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Update device control (fan/heater)
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

  /// Save incubation cycle
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

      // Save copy in cycles for archiving
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

  /// Get current cycle for user
  Future<IncubationCycle?> getCurrentCycle(
    String userId,
    List<StageConfig> stages,
  ) async {
    try {
      final snapshot =
          await _database.child('users/$userId/currentCycle').get();

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

  /// Save stage transition history
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

  /// Clean old readings (keep only last N readings)
  Future<void> cleanOldReadings(String unitId, {int keepLast = 100}) async {
    try {
      final snapshot =
          await _database.child('units/$unitId/history').orderByKey().get();

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

  /// Save user data
  Future<void> saveUserData(String userId, UserData userData) async {
    try {
      await _database.child('users/$userId').set(userData.toJson());
    } catch (e) {
      throw Exception('فشل في حفظ بيانات المستخدم: $e');
    }
  }

  /// Get user data
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

  /// Dispose resources
  void dispose() {
    _sensorSubscription?.cancel();
  }
}
