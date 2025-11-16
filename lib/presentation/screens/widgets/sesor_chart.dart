import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:incubation_app/data/models/data_model.dart';

class SensorChart extends StatelessWidget {
  final List<SensorData> sensorHistory;
  final bool showTemperature;

  const SensorChart({
    super.key,
    required this.sensorHistory,
    this.showTemperature = true,
  });

  @override
  Widget build(BuildContext context) {
    if (sensorHistory.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          'لا توجد بيانات كافية',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            showTemperature ? 'منحنى درجة الحرارة' : 'منحنى الرطوبة',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              _buildChartData(),
              duration: const Duration(milliseconds: 250),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final data = sensorHistory.take(20).toList(); // آخر 20 قراءة

    final spots = data.asMap().entries.map((entry) {
      final index = entry.key;
      final sensor = entry.value;
      final value = showTemperature ? sensor.temperature : sensor.humidity;
      return FlSpot(index.toDouble(), value);
    }).toList();

    // حساب min و max للقيم
    final values = spots.map((s) => s.y).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final padding = range * 0.2;

    return LineChartData(
      minY: (minValue - padding).floorToDouble(),
      maxY: (maxValue + padding).ceilToDouble(),
      minX: 0,
      maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: showTemperature ? 1 : 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.white.withOpacity(0.1), strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: spots.length > 10 ? 5 : 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= data.length) return const SizedBox();

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${value.toInt()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            interval: showTemperature ? 1 : 5,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}${showTemperature ? "°" : "%"}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.2)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: showTemperature
              ? const Color(0xFFFF6B6B)
              : const Color(0xFF4ECDC4),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: showTemperature
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF4ECDC4),
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                (showTemperature
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF4ECDC4))
                    .withOpacity(0.3),
                (showTemperature
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF4ECDC4))
                    .withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 8,
          tooltipPadding: const EdgeInsets.all(8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index >= data.length) return null;

              final sensor = data[index];
              final time = sensor.timestamp;

              return LineTooltipItem(
                '${showTemperature ? "حرارة" : "رطوبة"}: ${spot.y.toStringAsFixed(1)}${showTemperature ? "°C" : "%"}\n'
                '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
