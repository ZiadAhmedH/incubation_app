import 'package:flutter/material.dart';

class FeedingIndicator extends StatelessWidget {
  final int currentFeeding;
  final int totalFeedings;

  const FeedingIndicator({
    super.key,
    required this.currentFeeding,
    required this.totalFeedings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF52B788), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant, color: Color(0xFF95D5B2), size: 20),
              const SizedBox(width: 8),
              const Text(
                'جدول التغذية اليومي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(totalFeedings, (index) {
              final feedingNumber = index + 1;
              final isCompleted = feedingNumber <= currentFeeding;
              final isCurrent = feedingNumber == currentFeeding;

              return Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? const Color(0xFF52B788)
                          : Colors.white24,
                      shape: BoxShape.circle,
                      border: isCurrent
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : Text(
                              '$feedingNumber',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFeedingTime(feedingNumber),
                    style: TextStyle(
                      color: isCompleted
                          ? const Color(0xFF95D5B2)
                          : Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getFeedingTime(int number) {
    // For production, you can use actual times if needed:
    // const times = ['6 ص', '12 ظ', '6 م', '12 م'];
    // if (number - 1 < times.length) return times[number - 1];
    return 'الوجبة $number';
  }
}
