import 'package:incubation_app/data/models/data_model.dart';
import '../../../data/repositories/incubation_repository.dart';

class StopCycleUseCase {
  final IncubationRepository _repository;

  StopCycleUseCase(this._repository);

  Future<IncubationCycle> call(String userId, IncubationCycle cycle) async {
    final stopped = cycle.copyWith(isActive: false);
    await _repository.saveCycle(userId, stopped);
    return stopped;
  }
}
