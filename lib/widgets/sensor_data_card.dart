import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:incubation_app/models/data_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:incubation_app/viewModel/cubit/incubation_cubit.dart';

class SensorDataCard extends StatelessWidget {
  final SensorData? sensorData;
  const SensorDataCard({super.key, required this.sensorData});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<IncubationCubit>();
    final config = cubit.getCurrentStageConfig();

    if (sensorData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2D6A4F),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF52B788)),
          ),
        ),
      );
    }

    final tempInRange = cubit.isTemperatureInRange();
    final humInRange = cubit.isHumidityInRange();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'القراءات الحالية',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _reading(
                  Icons.thermostat,
                  'درجة الحرارة',
                  '${sensorData?.temperature.toStringAsFixed(1)}°C',
                  tempInRange,
                  config != null
                      ? '${config.temperatureRange.min}-${config.temperatureRange.max}°C'
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _reading(
                  Icons.water_drop,
                  'الرطوبة',
                  '${sensorData?.humidity.toStringAsFixed(1)}%',
                  humInRange,
                  config != null
                      ? '${config.humidityRange.min}-${config.humidityRange.max}%'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'آخر تحديث: ${DateFormat('HH:mm:ss').format(sensorData!.timestamp)}',
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _reading(
    IconData icon,
    String label,
    String value,
    bool ok,
    String? range,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFF40916C) : const Color(0xFF9B2226),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.9))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (range != null) ...[
            const SizedBox(height: 4),
            Text(
              range,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
