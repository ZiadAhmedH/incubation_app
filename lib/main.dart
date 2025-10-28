import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:incubation_app/firebase_options.dart';
import 'package:incubation_app/screens/home-sceen.dart';
import 'package:incubation_app/screens/register_screen.dart';
import 'package:incubation_app/services/local_notification_service.dart';
import 'package:incubation_app/services/push_notification_service.dart';
import 'viewModel/cubit/incubation_cubit.dart';
import 'viewModel/cubit/incubation_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase (اختياري للمحاكاة)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase initialization failed: $e');
    // استمر بدون Firebase (المحاكاة فقط)
  }

 await Future.wait(
    [
      PushNotificationService.initialize(),
      LocalNotificationService.init(),
    ],
  );

  

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IncubationCubit(),
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
        // حالة التحميل الأولي
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

        // لا يوجد مستخدم مسجل - اذهب لشاشة التسجيل
        if (state is IncubationNoCycle) {
          return const RegistrationScreen();
        }

        // المستخدم مسجل - اذهب للشاشة الرئيسية
        return const HomeScreen();
      },
    );
  }
}
