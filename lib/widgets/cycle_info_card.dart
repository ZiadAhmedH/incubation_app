import 'package:flutter/material.dart';
import 'package:incubation_app/models/data_model.dart';
import 'package:intl/intl.dart';

class CycleInfoCard extends StatelessWidget {
  final IncubationCycle cycle;
  const CycleInfoCard({super.key, required this.cycle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'معلومات الدورة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cycle.isActive
                      ? const Color(0xFF52B788)
                      : const Color(0xFF6C757D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cycle.isActive ? 'نشطة' : 'متوقفة',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoRow('المرحلة الحالية', cycle.currentStage.arabicName),
          _infoRow(
            'تاريخ البدء',
            DateFormat('yyyy-MM-dd').format(cycle.startDate),
          ),
          _infoRow('الأيام المتبقية', '${cycle.daysRemaining}'),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (cycle.progress / 100).clamp(0, 1),
              minHeight: 10,
              backgroundColor: const Color(0xFF40916C),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFB800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'التقدم: ${cycle.progress.toStringAsFixed(1)}%',
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8))),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
