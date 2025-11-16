// filepath: lib/services/native_foreground_service.dart
import 'package:flutter/services.dart';

class NativeForegroundService {
  static const MethodChannel _channel =
      MethodChannel('incubation_app/foreground_service');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('startService');
    } catch (e) {
      print('Error starting foreground service: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopService');
    } catch (e) {
      print('Error stopping foreground service: $e');
    }
  }
}
