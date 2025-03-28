import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ItemTrendLineChart extends StatelessWidget {
  final Map<String, int> data;
  final GlobalKey repaintKey;

  const ItemTrendLineChart({
    required this.data,
    required this.repaintKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final spots = <FlSpot>[];
    final labels = <int, String>{};

    for (int i = 0; i < sortedEntries.length; i++) {
      final dateStr = sortedEntries[i].key;
      final count = sortedEntries[i].value;

      spots.add(FlSpot(i.toDouble(), count.toDouble()));

      final parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate != null) {
        labels[i] = DateFormat('MMM dd').format(parsedDate); // örn. Mar 03
      } else {
        labels[i] = dateStr;
      }
    }

    final maxY = (data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b)) + 2;

    return RepaintBoundary(
      key: repaintKey,
      child: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            maxY: maxY.toDouble(),
            minY: 0,
            gridData: FlGridData(show: true),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
               getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    final label = labels[index] ?? '';
                    return LineTooltipItem(
                      '$label\n${spot.y.toInt()} items',
                      const TextStyle(color: Colors.white),
                    );
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  interval: 2,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (labels.containsKey(index)) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          labels[index]!,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                spots: spots,
                barWidth: 3,
                color: Colors.blueAccent,
                belowBarData: BarAreaData(show: false),
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
