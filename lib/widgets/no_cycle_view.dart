import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:incubation_app/presentation/cubit/incubation_cubit.dart';
import 'package:incubation_app/presentation/cubit/incubation_state.dart';

class NoCycleView extends StatelessWidget {
  final IncubationState state;
  const NoCycleView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final user = state is IncubationRegistered ? (state as IncubationRegistered).userData : null;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (user != null) ...[
            Text(
              'مرحباً ${user.userName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الوحدة: ${user.unitName}',
              style: TextStyle(color: Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: 20),
          ],
          const Icon(
            Icons.bug_report_outlined,
            size: 90,
            color: Color(0xFF52B788),
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد دورة حضانة نشطة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => context.read<IncubationCubit>().startNewCycle(),
            icon: const Icon(Icons.play_arrow),
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
