import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:incubation_app/presentation/cubit/incubation_state.dart';
import 'package:incubation_app/presentation/screens/widgets/feeding_indicator.dart';
import 'package:incubation_app/services/oneSignal_serveice.dart';
import 'package:incubation_app/services/semulation_service.dart';
import 'package:incubation_app/widgets/user_info_card.dart';
import 'package:incubation_app/widgets/cycle_info_card.dart';
import 'package:incubation_app/widgets/sensor_data_card.dart';
import 'package:incubation_app/widgets/charts_section.dart';
import 'package:incubation_app/widgets/device_control_card.dart';
import 'package:incubation_app/presentation/screens/stage_monitoring.dart';
import 'package:incubation_app/widgets/no_cycle_view.dart';
import 'package:incubation_app/widgets/completed_view.dart';

import '../cubit/incubation_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  Timer? _progressTimer;
  late AnimationController _fabController;
  late AnimationController _cardController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startProgressTimer();
  }

  void _initializeAnimations() {
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    ));
    _cardController.forward();
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _fabController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _listener(BuildContext context, IncubationState state) {
    if (state is IncubationStageChanged) {
      _cardController.reset();
      _cardController.forward();
      _showSnackBar(
        context,
        icon: Icons.check_circle,
        message: 'تم الانتقال إلى: ${state.newStage.arabicName}',
        backgroundColor: const Color(0xFF52B788),
        duration: 3,
      );
    } else if (state is IncubationCompleted) {
      _showSnackBar(
        context,
        icon: Icons.celebration,
        message: 'تمت دورة الحضانة بنجاح! 🎉',
        backgroundColor: const Color(0xFF52B788),
        duration: 4,
      );
    } else if (state is IncubationError) {
      _showSnackBar(
        context,
        icon: Icons.error_outline,
        message: state.message,
        backgroundColor: Colors.red,
        duration: 3,
      );
    }
  }

  void _showSnackBar(
    BuildContext context, {
    required IconData icon,
    required String message,
    required Color backgroundColor,
    required int duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: duration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: _buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1B4332).withOpacity(0.9),
              const Color(0xFF2D6A4F).withOpacity(0.8),
            ],
          ),
        ),
      ),
      title: _buildAppBarTitle(),
      actions: [_buildAppBarAction(context)],
    );
  }

  Widget _buildAppBarTitle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.eco,
            color: Color(0xFFD8F3DC),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'BombyxCare',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarAction(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        onPressed: () => _navigateToStageMonitoring(context),
        icon: const Icon(Icons.timeline, color: Colors.white),
        tooltip: 'متابعة المراحل',
      ),
    );
  }

  void _navigateToStageMonitoring(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            BlocProvider.value(
          value: context.read<IncubationCubit>(),
          child: const StageMonitoringScreen(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F2027),
            Color(0xFF1B4332),
            Color(0xFF2D6A4F),
          ],
        ),
      ),
      child: BlocConsumer<IncubationCubit, IncubationState>(
        listener: _listener,
        builder: (context, state) => _buildStateContent(context, state),
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, IncubationState state) {
    if (state is IncubationNoCycle || state is IncubationRegistered) {
      return _buildNoCycleView(state);
    }

    if (state is IncubationRunning || state is IncubationStageChanged) {
      return _buildRunningView(context, state);
    }

    if (state is IncubationCompleted) {
      return _buildCompletedView(state);
    }

    return _buildLoadingView();
  }

  Widget _buildNoCycleView(IncubationState state) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _cardController,
        child: NoCycleView(state: state),
      ),
    );
  }

  Widget _buildRunningView(BuildContext context, IncubationState state) {
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

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _cardController,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 12),
              _AnimatedCard(
                delay: 100,
                child:  UserInfoCard(userData: user),
              ),
              const SizedBox(height: 12),
              _AnimatedCard(
                delay: 200,
                child:  CycleInfoCard(cycle: cycle),
              ),
              const SizedBox(height: 12),
              _AnimatedCard(
                delay: 300,
                child:  SensorDataCard(sensorData: sensor),
              ),
              const SizedBox(height: 12),
              _AnimatedCard(
                delay: 400,
                child:  ChartsSection(sensorHistory: history),
              ),
              const SizedBox(height: 12),
              _AnimatedCard(
                delay: 500,
                child: _solidCard(child: DeviceControlCard(sensorData: sensor)),
              ),
              const SizedBox(height: 12),
              // _AnimatedCard(
              //   delay: 600,
              //   child: BlocBuilder<IncubationCubit, IncubationState>(
              //     builder: (context, state) {
              //       final cubit = context.read<IncubationCubit>();
              //       return _solidCard(
              //         child: FeedingIndicator(
              //           currentFeeding:
              //               cubit.feedingSchedule.currentFeedingCount,
              //         ),
              //       );
              //     },
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedView(IncubationCompleted state) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _cardController,
        child: CompletedView(
          cycle: state.cycle,
          userData: state.userData,
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (value * 0.2),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري التحميل...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF52B788).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _sendTestNotification(context),
          backgroundColor: const Color(0xFF52B788),
          icon: const Icon(Icons.notifications_active, color: Colors.white),
          label: const Text(
            'اختبار إشعار',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    final cubit = context.read<IncubationCubit>();
    final userId = cubit.currentUser?.userName;

    if (userId == null) {
      _showSnackBar(
        context,
        icon: Icons.error_outline,
        message: 'لم يتم العثور على معرف المستخدم',
        backgroundColor: Colors.red,
        duration: 3,
      );
      return;
    }

    print('🧪 اختبار إرسال إشعار لـ $userId');

    // Animate FAB
    await _fabController.reverse();
    _fabController.forward();

    // Send notification
    await OneSignalService.sendNotificationToUser(
      userId: userId,
      title: '🧪 إشعار تجريبي',
      message: 'هذا إشعار تجريبي من تطبيق BombyxCare.',
       androidSound: 'notification',
        
    );

    if (context.mounted) {
      _showSnackBar(
        context,
        icon: Icons.send,
        message: 'تم إرسال الإشعار التجريبي ✅',
        backgroundColor: const Color(0xFF52B788),
        duration: 3,
      );
    }
  }

  Widget _solidCard({required Widget child, EdgeInsets? padding}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

// ========================================
// 🎨 Animated Card Widget
// ========================================

class _AnimatedCard extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedCard({
    required this.child,
    this.delay = 0,
  });

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}
