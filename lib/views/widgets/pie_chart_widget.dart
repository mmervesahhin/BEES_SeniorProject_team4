import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, int> data;
  final GlobalKey repaintKey;

  const CategoryPieChart({
    required this.data,
    required this.repaintKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (sum, val) => sum + val);
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    final sections = data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final label = entry.value.key;
      final value = entry.value.value;
      final percent = total == 0 ? 0 : (value / total) * 100;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: value.toDouble(),
        title: '${label}: ${value}',
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
      );
    }).toList();

    return RepaintBoundary(
      key: repaintKey,
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 5,
            children: data.keys.toList().asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: colors[index % colors.length],
                  ),
                  const SizedBox(width: 4),
                  Text(label),
                ],
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
