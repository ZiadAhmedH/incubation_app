import '../../../data/repositories/incubation_repository.dart';
import '../../../services/semulation_service.dart';

class UpdateDeviceControlUseCase {
  final IncubationRepository _repository;
  final SimulationService _simulation;

  UpdateDeviceControlUseCase(this._repository, this._simulation);

  Future<void> call(String unitId, bool fan, bool heater) async {
    await _repository.updateDeviceControl(unitId, fan, heater);
    _simulation.updateDeviceControl(fan: fan, heater: heater);
  }
}
