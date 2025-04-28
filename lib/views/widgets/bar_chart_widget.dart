import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ItemTypeBarChart extends StatelessWidget {
  final Map<String, int> data;
  final GlobalKey repaintKey;

  const ItemTypeBarChart({
    required this.data,
    required this.repaintKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final items = data.entries.toList();

    final colors = [
      Color(0xFF4E79A7), // Deep Blue
      Color(0xFFF28E2B), // Orange
      Color(0xFFE15759), // Soft Red
      Color(0xFF76B7B2), // Teal
      Color(0xFF59A14F), // Green
      Color(0xFFEDC949), // Yellow
      Color(0xFFAF7AA1), // Mauve
      Color(0xFFFF9DA7), // Light Coral
      Color(0xFF9C755F), // Brownish
      Color(0xFFBAB0AC), // Gray
    ];

    return RepaintBoundary(
      key: repaintKey,
      child: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (data.values.isEmpty
                        ? 1
                        : data.values.reduce((a, b) => a > b ? a : b))
                    .toDouble() +
                2,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final itemType = items[groupIndex].key;
                  return BarTooltipItem(
                    '$itemType\n${rod.toY.round()} items',
                    TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  );
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
                      style: TextStyle(fontSize: 10),
                    );
                  },
                  interval: 5,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < items.length) {
                      return SideTitleWidget(
                        child: Text(
                          items[index].key,
                          style: TextStyle(fontSize: 10),
                        ),
                        meta: meta,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: items.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value.toDouble(),
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                    color:
                        colors[index % colors.length], // 🎯 color from palette
                  ),
                ],
                showingTooltipIndicators: [0],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
