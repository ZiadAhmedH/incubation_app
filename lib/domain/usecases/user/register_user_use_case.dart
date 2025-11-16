import '../../../data/models/data_model.dart';
import '../../../data/repositories/incubation_repository.dart';

class RegisterUserUseCase {
  final IncubationRepository _repository;

  RegisterUserUseCase(this._repository);

  Future<UserData> call(String name, String unit, int eggs) async {
    final user = UserData(
      userName: name,
      unitName: unit,
      eggCount: eggs,
      registrationDate: DateTime.now(),
    );

    await _repository.saveUser(user);
    return user;
  }
}
