import 'package:flutter/material.dart';
import 'package:incubation_app/data/models/data_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:incubation_app/presentation/cubit/incubation_cubit.dart';

class CompletedView extends StatelessWidget {
  final IncubationCycle cycle;
  final UserData userData;
  const CompletedView({super.key, required this.cycle, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 100,
            color: Color(0xFF52B788),
          ),
          const SizedBox(height: 20),
          const Text(
            'تمت دورة الحضانة بنجاح!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'المدة الإجمالية: ${cycle.totalDuration} يوم',
            style: TextStyle(color: Colors.white.withOpacity(0.85)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<IncubationCubit>().startNewCycle(),
            icon: const Icon(Icons.refresh),
            label: const Text('بدء دورة جديدة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF52B788),
            ),
          ),
        ],
      ),
    );
  }
}
