import 'dart:async';
import '../../../data/data_sources/remote/firebase_service.dart';
import '../../../services/semulation_service.dart';

class DeviceControlService {
  final FirebaseService _fb;
  final SimulationService _sim;
  StreamSubscription? _sub;

  DeviceControlService(this._fb, this._sim);

  void start(String unitId) {
    stop();
    _sub = _fb.watchDeviceControl(unitId).listen((control) {
      if (control != null) {
        _sim.updateDeviceControl(
          fan: control['fan'] ?? false,
          heater: control['heater'] ?? false,
        );
      }
    }, onError: (e) => print('DeviceControlService error: $e'));
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void dispose() => stop();
}

extension SimulationServiceDeviceControl on SimulationService {
  void updateDeviceControl({required bool fan, required bool heater}) {
    // TODO: implement actual logic to apply fan and heater states
  }
}
