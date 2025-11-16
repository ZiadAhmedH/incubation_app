import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:incubation_app/presentation/cubit/incubation_cubit.dart';
import 'package:incubation_app/presentation/cubit/incubation_state.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:intl/intl.dart';

import '../../data/models/data_model.dart';

class StageMonitoringScreen extends StatelessWidget {
  const StageMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B4332),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4332),
        elevation: 0,
        title: const Text(
          'مراقبة الحضانة',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              // Refresh data
            },
          ),
        ],
      ),
      body: BlocBuilder<IncubationCubit, IncubationState>(
        builder: (context, state) {
          if (state is! IncubationRunning) {
            return const Center(
              child: Text(
                'لا توجد دورة نشطة',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final cycle = state.cycle;
          final sensorData = state.latestSensorData;
          final config = context
              .read<IncubationCubit>()
              .getCurrentStageConfig();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Circle
                _buildProgressCircle(cycle, config),
                const SizedBox(height: 32),

                // Temperature and Humidity
                Row(
                  children: [
                    Expanded(
                      child: _buildSensorCard(
                        icon: Icons.thermostat,
                        label: 'درجة الحرارة',
                        value:
                            sensorData?.temperature.toStringAsFixed(1) ?? '--',
                        unit: '°C',
                        isNormal: context
                            .read<IncubationCubit>()
                            .isTemperatureInRange(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSensorCard(
                        icon: Icons.water_drop,
                        label: 'رطوبة',
                        value: sensorData?.humidity.toStringAsFixed(0) ?? '--',
                        unit: '%',
                        isNormal: context
                            .read<IncubationCubit>()
                            .isHumidityInRange(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Optimal Conditions Button
                _buildOptimalConditionsButton(context),
                const SizedBox(height: 32),

                // Stage Timeline
                _buildStageTimeline(cycle),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressCircle(IncubationCycle cycle, StageConfig? config) {
    final progress = cycle.progress / 100;
    final daysRemaining = cycle.currentStageDaysRemaining;
    final totalDays = config?.durationDays ?? 1;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'مرحلة ${cycle.currentStage.arabicName}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          CircularPercentIndicator(
            radius: 120,
            lineWidth: 20,
            percent: progress,
            center: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'اليوم $daysRemaining / $totalDays',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            progressColor: const Color(0xFFFFB800),
            backgroundColor: const Color(0xFF40916C),
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required bool isNormal,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isNormal ? const Color(0xFF40916C) : const Color(0xFF9B2226),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  unit,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimalConditionsButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _showOptimalConditions(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2D6A4F),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: const Text(
        'الظروف المثالية',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showOptimalConditions(BuildContext context) {
    final config = context.read<IncubationCubit>().getCurrentStageConfig();
    if (config == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D6A4F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الظروف المثالية',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildOptimalRow(
              'درجة الحرارة',
              '${config.temperatureRange.optimal}°C',
              'النطاق: ${config.temperatureRange.min}-${config.temperatureRange.max}°C',
            ),
            const SizedBox(height: 16),
            _buildOptimalRow(
              'الرطوبة',
              '${config.humidityRange.optimal}%',
              'النطاق: ${config.humidityRange.min}-${config.humidityRange.max}%',
            ),
            if (config.feeding != null) ...[
              const SizedBox(height: 16),
              _buildOptimalRow(
                'التغذية',
                '${config.feeding!.frequency} مرات/يوم',
                config.feeding!.notes,
              ),
            ],
            if (config.cleaning != null) ...[
              const SizedBox(height: 16),
              _buildOptimalRow(
                'التنظيف',
                '${config.cleaning!.frequency} مرات/يوم',
                config.cleaning!.notes,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptimalRow(String label, String value, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Color(0xFFFFB800),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildStageTimeline(IncubationCycle cycle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'شاشة تتبع مراحل النمو',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ...IncubationStage.values.asMap().entries.map((entry) {
            final index = entry.key;
            final stage = entry.value;
            final isPast = stage.order < cycle.currentStage.order;
            final isCurrent = stage == cycle.currentStage;
            final isLast = index == IncubationStage.values.length - 1;

            return _buildTimelineItem(
              stage: stage,
              isPast: isPast,
              isCurrent: isCurrent,
              isLast: isLast,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IncubationStage stage,
    required bool isPast,
    required bool isCurrent,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPast
                    ? const Color(0xFF52B788)
                    : isCurrent
                    ? const Color(0xFFFFB800)
                    : const Color(0xFF6C757D),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isPast
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        '${stage.order + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isPast
                    ? const Color(0xFF52B788)
                    : const Color(0xFF6C757D).withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.arabicName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: Colors.white,
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF52B788),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'نشطة',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
