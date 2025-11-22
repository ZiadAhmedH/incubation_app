import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';

class ESP32Simulator {
  Timer? _timer;
  final Random _random = Random();
  bool _isRunning = false;
  
  double _currentTemp = 25.0;
  double _currentHumidity = 70.0;

  /// Start simulating ESP32 sensor data
  void startSimulation(String unitId, {
    double? targetTemp,
    double? targetHumidity,
  }) {
    if (_isRunning) {
      print('⚠️ Simulator already running');
      return;
    }

    print('🤖 Starting ESP32 Simulator for unit: $unitId');
    _isRunning = true;
    
    _currentTemp = targetTemp ?? 25.0;
    _currentHumidity = targetHumidity ?? 70.0;

    // Send data every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _sendSensorData(unitId);
    });
  }

  /// Stop the simulation
  void stopSimulation() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    print('🛑 ESP32 Simulator stopped');
  }

  /// Simulate and send sensor data to Firebase
  Future<void> _sendSensorData(String unitId) async {
    try {
      // Simulate realistic sensor readings with gradual changes
      _currentTemp += (_random.nextDouble() - 0.5) * 0.5;
      _currentHumidity += (_random.nextDouble() - 0.5) * 2.0;

      // Keep within realistic bounds
      _currentTemp = _currentTemp.clamp(22.0, 28.0);
      _currentHumidity = _currentHumidity.clamp(60.0, 85.0);

      // Auto control based on thresholds
      final fanOn = _currentTemp > 26.0;
      final heaterOn = _currentTemp < 24.0;

      // Adjust temperature based on control
      if (heaterOn) _currentTemp += 0.3;
      if (fanOn) _currentTemp -= 0.3;

      final sensorData = {
        'temperature': double.parse(_currentTemp.toStringAsFixed(2)),
        'humidity': double.parse(_currentHumidity.toStringAsFixed(2)),
        'timestamp': DateTime.now().toIso8601String(),
        'fan': fanOn,
        'heater': heaterOn,
      };

      final database = FirebaseDatabase.instance;

      // Save current data
      await database.ref('$unitId/sensorData').set(sensorData);

      // Save to history
      await database.ref('$unitId/history').push().set(sensorData);

      print('📡 ESP32 Data: 🌡️${_currentTemp.toStringAsFixed(1)}°C 💧${_currentHumidity.toStringAsFixed(1)}%');
    } catch (e) {
      print('❌ ESP32 Simulator Error: $e');
    }
  }

  /// Send a single test data
  Future<void> sendTestData(String unitId) async {
    print('🧪 Sending test data...');
    await _sendSensorData(unitId);
  }

  void dispose() {
    stopSimulation();
  }
}