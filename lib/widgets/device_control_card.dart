import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:incubation_app/models/data_model.dart';
import 'package:incubation_app/viewModel/cubit/incubation_cubit.dart';

class DeviceControlCard extends StatelessWidget {
  final SensorData? sensorData;
  const DeviceControlCard({super.key, required this.sensorData});

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
          const Text(
            'التحكم في الأجهزة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _switchTile(
                  context,
                  Icons.air,
                  'المروحة',
                  sensorData?.fanOn ?? false,
                  (v) => context.read<IncubationCubit>().updateDeviceControl(
                    fan: v,
                    heater: sensorData?.heaterOn ?? false,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _switchTile(
                  context,
                  Icons.lightbulb,
                  'السخان',
                  sensorData?.heaterOn ?? false,
                  (v) => context.read<IncubationCubit>().updateDeviceControl(
                    fan: sensorData?.fanOn ?? false,
                    heater: v,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switchTile(
    BuildContext context,
    IconData icon,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? const Color(0xFF40916C) : const Color(0xFF1B4332),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(icon, color: value ? const Color(0xFFFFB800) : Colors.white70),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 6),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFFB800),
            activeTrackColor: const Color(0xFF52B788),
          ),
        ],
      ),
    );
  }
}
