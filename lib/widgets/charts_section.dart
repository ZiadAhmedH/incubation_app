import 'package:flutter/material.dart';
import 'package:incubation_app/data/models/data_model.dart';
import 'package:incubation_app/presentation/screens/widgets/sesor_chart.dart';

class ChartsSection extends StatelessWidget {
  final List<SensorData> sensorHistory;
  const ChartsSection({super.key, required this.sensorHistory});

  @override
  Widget build(BuildContext context) {
    if (sensorHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        if (sensorHistory.length > 2)
          SensorChart(sensorHistory: sensorHistory, showTemperature: true),
        const SizedBox(height: 12),
        if (sensorHistory.length > 2)
          SensorChart(sensorHistory: sensorHistory, showTemperature: false),
      ],
    );
  }
}
