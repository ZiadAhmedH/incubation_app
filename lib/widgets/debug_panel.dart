import 'package:flutter/material.dart';
import '../../data/models/data_model.dart';
import '../../services/semulation_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../presentation/cubit/incubation_cubit.dart';

class DebugPanel extends StatelessWidget {
  final IncubationCycle cycle;
  const DebugPanel({super.key, required this.cycle});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // وقت المرحلة الحالية
    final timeSinceStageStart = now.difference(cycle.stageStartDate);
    final stageMinutesPassed = timeSinceStageStart.inMinutes;
    final stageSecondsPassed = timeSinceStageStart.inSeconds % 60;

    // الوقت الكلي
    final totalTimePassed = now.difference(cycle.startDate);
    final totalDaysPassed = SimulationService.debugMode
        ? totalTimePassed.inMinutes
        : totalTimePassed.inDays;

    // تكوين المرحلة الحالية
    final currentStageConfig = cycle.stages.firstWhere(
      (s) => s.stage == cycle.currentStage,
      orElse: () => StageConfig(
        stage: cycle.currentStage,
        durationDays: 0,
        temperatureRange: const TemperatureRange(min: 20, max: 30, optimal: 25),
        humidityRange: const HumidityRange(min: 50, max: 80, optimal: 65),
      ),
    );

    // حساب اليوم الكلي في الدورة (من 44)
    final totalDuration = cycle.stages.fold<int>(
      0,
      (sum, config) => sum + config.durationDays,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade900.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade600, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              Icon(Icons.bug_report, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'وضع التطوير - سرعة عالية (دقيقة = يوم)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white38, height: 20),

          // التقدم الكلي
          _buildInfoRow(
            'التقدم الكلي',
            'اليوم $totalDaysPassed من $totalDuration',
            Icons.calendar_today,
          ),
          const SizedBox(height: 8),
          _buildProgressBar(
            value: (totalDaysPassed / totalDuration).clamp(0.0, 1.0),
            color: Colors.yellow,
            percentage: cycle.progress,
          ),

          const SizedBox(height: 16),

          // معلومات المرحلة
          _buildInfoRow(
            'المرحلة الحالية',
            cycle.currentStage.arabicName,
            Icons.egg_outlined,
          ),
          const SizedBox(height: 8),

          _buildInfoRow(
            'الوقت في المرحلة',
            '$stageMinutesPassed دقيقة و $stageSecondsPassed ثانية',
            Icons.timer,
          ),
          const SizedBox(height: 8),

          _buildInfoRow(
            'مدة المرحلة',
            '${currentStageConfig.durationDays} ${SimulationService.debugMode ? "دقيقة" : "يوم"}',
            Icons.timelapse,
          ),

          const SizedBox(height: 8),
          _buildProgressBar(
            value: currentStageConfig.durationDays > 0
                ? (stageMinutesPassed / currentStageConfig.durationDays)
                    .clamp(0.0, 1.0)
                : 0.0,
            color: Colors.green,
            percentage: cycle.currentStageProgress,
          ),

          const SizedBox(height: 16),

          // أزرار التحكم
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context
                        .read<IncubationCubit>()
                        .checkStageTransitionManually();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم فحص الانتقال يدوياً'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('فحص الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<IncubationCubit>().skipToNextStage();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم الانتقال للمرحلة التالية'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.skip_next, size: 18),
                  label: const Text('التالي'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar({
    required double value,
    required Color color,
    required double percentage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
