class BarChartDataModel {
  final String label;
  final int value;

  BarChartDataModel({required this.label, required this.value});
}

class LineChartDataModel {
  final String date;
  final int count;

  LineChartDataModel({required this.date, required this.count});
}

class PieChartDataModel {
  final String label;
  final int value;

  PieChartDataModel({required this.label, required this.value});
}
