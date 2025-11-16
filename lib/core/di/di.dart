import 'package:get_it/get_it.dart';
import '../../data/data_sources/local/local_storage_service.dart';
import '../../data/data_sources/remote/firebase_service.dart';
import '../../data/repositories/incubation_repository.dart';
import '../../domain/usecases/user/register_user_use_case.dart';
import '../../domain/usecases/cycle/start_cycle_use_case.dart';
import '../../domain/usecases/cycle/transition_stage_use_case.dart';
import '../../domain/usecases/cycle/stop_cycle_use_case.dart';
import '../../domain/usecases/device/update_device_control.dart';
import '../../services/semulation_service.dart';
import '../../services/notification_scheduler.dart';
import '../../presentation/cubit/incubation_cubit.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // Data Sources
  getIt.registerLazySingleton<FirebaseService>(() => FirebaseService());
  getIt.registerLazySingleton<LocalStorageService>(() => LocalStorageService());

  // Services
  getIt.registerLazySingleton<SimulationService>(() => SimulationService());
  getIt.registerLazySingleton<NotificationScheduler>(
      () => NotificationScheduler());

  // Repository
  getIt.registerLazySingleton<IncubationRepository>(
    () => IncubationRepository(
      getIt<FirebaseService>(),
      getIt<LocalStorageService>(),
    ),
  );

  // Use Cases
  getIt.registerFactory<RegisterUserUseCase>(
    () => RegisterUserUseCase(getIt<IncubationRepository>()),
  );

  getIt.registerFactory<StartCycleUseCase>(
    () => StartCycleUseCase(
      getIt<IncubationRepository>(),
      getIt<SimulationService>(),
    ),
  );

  getIt.registerFactory<TransitionStageUseCase>(
    () => TransitionStageUseCase(
      getIt<IncubationRepository>(),
    ),
  );

  getIt.registerFactory<StopCycleUseCase>(
    () => StopCycleUseCase(getIt<IncubationRepository>()),
  );

  getIt.registerFactory<UpdateDeviceControlUseCase>(
    () => UpdateDeviceControlUseCase(
      getIt<IncubationRepository>(),
      getIt<SimulationService>(),
    ),
  );

  // Cubit
  getIt.registerFactory<IncubationCubit>(
    () => IncubationCubit(
      getIt<IncubationRepository>(),
      getIt<FirebaseService>(),
      getIt<LocalStorageService>(), // ✅ إضافة LocalStorage
      getIt<SimulationService>(),
      getIt<RegisterUserUseCase>(),
      getIt<StartCycleUseCase>(),
      getIt<TransitionStageUseCase>(),
      getIt<StopCycleUseCase>(),
      getIt<UpdateDeviceControlUseCase>(),
    ),
  );
}
