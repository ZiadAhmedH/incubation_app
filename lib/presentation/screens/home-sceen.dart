import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:incubation_app/data/models/data_model.dart';
import 'package:incubation_app/presentation/screens/widgets/feeding_indicator.dart';
import 'package:incubation_app/services/oneSignal_serveice.dart';
import 'package:incubation_app/services/semulation_service.dart';
import 'package:incubation_app/presentation/cubit/incubation_cubit.dart';
import 'package:incubation_app/presentation/cubit/incubation_state.dart';
import 'package:incubation_app/widgets/debug_panel.dart';
import 'package:incubation_app/widgets/user_info_card.dart';
import 'package:incubation_app/widgets/cycle_info_card.dart';
import 'package:incubation_app/widgets/sensor_data_card.dart';
import 'package:incubation_app/widgets/charts_section.dart';
import 'package:incubation_app/widgets/device_control_card.dart';
import 'package:incubation_app/presentation/screens/stage_monitoring.dart';
import 'package:incubation_app/widgets/no_cycle_view.dart';
import 'package:incubation_app/widgets/completed_view.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _listener(BuildContext context, IncubationState state) {
    if (state is IncubationStageChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الانتقال إلى: ${state.newStage.arabicName}'),
          backgroundColor: const Color(0xFF52B788),
        ),
      );
    } else if (state is IncubationCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تمت دورة الحضانة بنجاح! 🎉'),
          backgroundColor: Color(0xFF52B788),
        ),
      );
    } else if (state is IncubationError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'حضانة دودة القز',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<IncubationCubit>(),
                  child: const StageMonitoringScreen(),
                ),
              ),
            ),
            icon: const Icon(Icons.timeline, color: Colors.white),
          ),
        ],
      ),
      body: BlocConsumer<IncubationCubit, IncubationState>(
        listener: _listener,
        builder: (context, state) {
          if (state is IncubationNoCycle || state is IncubationRegistered) {
            return NoCycleView(state: state);
          }

          if (state is IncubationRunning || state is IncubationStageChanged) {
            final cycle = state is IncubationRunning
                ? state.cycle
                : (state as IncubationStageChanged).cycle;
            final user = state is IncubationRunning
                ? state.userData
                : (state as IncubationStageChanged).userData;
            final sensor = state is IncubationRunning
                ? state.latestSensorData
                : (state as IncubationStageChanged).latestSensorData;
            final history = state is IncubationRunning
                ? state.sensorHistory
                : (state as IncubationStageChanged).sensorHistory;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (SimulationService.debugMode) DebugPanel(cycle: cycle),
                  const SizedBox(height: 12),
                  UserInfoCard(userData: user),
                  const SizedBox(height: 12),
                  CycleInfoCard(cycle: cycle),
                  const SizedBox(height: 12),
                  SensorDataCard(sensorData: sensor),
                  const SizedBox(height: 12),
                  ChartsSection(sensorHistory: history),
                  const SizedBox(height: 12),
                  DeviceControlCard(sensorData: sensor),
                  // ✅ إضافة مؤشر التغذية
                  FeedingIndicator(
                    currentFeeding: context
                        .read<IncubationCubit>()
                        .feedingSchedule
                        .currentFeedingCount,
                  ),
                ],
              ),
            );
          }

          if (state is IncubationCompleted) {
            return CompletedView(cycle: state.cycle, userData: state.userData);
          }

          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
            ),
          );
        },
      ),
      // في مكان ما في الـ UI
      floatingActionButton: ElevatedButton(
        onPressed: () async {
          final cubit = context.read<IncubationCubit>();
          final userId = cubit.currentUser?.userName;

          if (userId != null) {
            print('🧪 اختبار إرسال إشعار لـ $userId');

            await OneSignalService.sendNotificationToUser(
              userId: userId,
              title: '🧪 اختبار برمجي',
              message: 'هذا إشعار تم إرساله من الكود مباشرة',
              data: {
                'type': 'test',
                'test_time': DateTime.now().toIso8601String(),
              },
            );
          }
        },
        child: const Text('اختبار إرسال إشعار'),
      ),
    );
  }
}
