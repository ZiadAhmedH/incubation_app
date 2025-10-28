import 'package:flutter/material.dart';
import 'package:incubation_app/models/data_model.dart';
import 'package:incubation_app/viewModel/cubit/incubation_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:incubation_app/services/semulation_service.dart';

class DebugPanel extends StatelessWidget {
  final IncubationCycle cycle;
  const DebugPanel({super.key, required this.cycle});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeSinceStageStart = now.difference(cycle.stageStartDate);
    final minutesPassed = timeSinceStageStart.inMinutes;
    final secondsPassed = timeSinceStageStart.inSeconds % 60;
    final currentStageConfig = cycle.stages.firstWhere(
      (s) => s.stage == cycle.currentStage,
    );
    final totalPassed = now.difference(cycle.startDate).inMinutes;
    final totalUnits = cycle.stages.fold<int>(
      0,
      (sum, c) => sum + c.durationDays,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.bug_report, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'وضع التطوير - سرعة عالية',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _row('المرحلة الحالية', cycle.currentStage.arabicName),
          _row(
            'الوقت في المرحلة',
            '$minutesPassed دقيقة و $secondsPassed ثانية',
          ),
          _row('مدة المرحلة', '${currentStageConfig.durationDays} دقيقة'),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (minutesPassed / currentStageConfig.durationDays).clamp(
              0,
              1,
            ),
            backgroundColor: Colors.orange.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            minHeight: 8,
          ),
          const SizedBox(height: 6),
          Text(
            'تقدم المرحلة: ${(cycle.currentStageProgress).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (cycle.progress / 100).clamp(0, 1),
            backgroundColor: Colors.orange.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
            minHeight: 8,
          ),
          const SizedBox(height: 6),
          Text(
            'التقدم الكلي: ${cycle.progress.toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.yellow),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context
                        .read<IncubationCubit>()
                        .checkStageTransitionManually();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم فحص الانتقال يدوياً')),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('فحص الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: const TextStyle(color: Colors.white70)),
        Text(
          v,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
