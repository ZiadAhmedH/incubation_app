import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:incubation_app/services/native_forground_service.dart';
import 'core/di/di.dart';
import 'firebase_options.dart';
import 'presentation/screens/home-sceen.dart';
import 'presentation/screens/register_screen.dart';
import 'services/background_task_service.dart';
import 'services/local_notification_service.dart';
import 'services/push_notification_service.dart';
import 'services/notification_scheduler.dart';
import 'presentation/cubit/incubation_cubit.dart';
import 'presentation/cubit/incubation_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup GetIt Service Locator
  await setupServiceLocator();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // Initialize Services
  try {
    await Future.wait([
      PushNotificationService.initialize(),
      LocalNotificationService.init(),
      NotificationScheduler.init(),
      NativeForegroundService.start(),
      // WorkmanagerService.initialize(), // ✅
    ]);
  } catch (e) {
    print('Services initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<IncubationCubit>(),
      child: MaterialApp(
        title: 'حضانة دودة القز',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF1B4332),
          scaffoldBackgroundColor: const Color(0xFF1B4332),
          fontFamily: 'Arial',
        ),
        home: const AppNavigator(),
      ),
    );
  }
}

class AppNavigator extends StatelessWidget {
  const AppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IncubationCubit, IncubationState>(
      builder: (context, state) {
        if (state is IncubationInitial) {
          return const Scaffold(
            backgroundColor: Color(0xFF1B4332),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
              ),
            ),
          );
        }

        if (state is IncubationNoCycle) {
          return const RegistrationScreen();
        }

        return const HomeScreen();
      },
    );
  }
}
