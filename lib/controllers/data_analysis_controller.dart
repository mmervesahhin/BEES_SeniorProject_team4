import 'dart:math' as math;
import 'package:bees/models/chart_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class DataAnalysisController extends ChangeNotifier {
  bool isLoading = false;

  DateTime? startDate;
  DateTime? endDate;

Future<DateTime?> selectStartDate(BuildContext context) async {
  DateTime? picked = await showDatePicker(
    context: context,
    initialDate: startDate ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );
  return picked;
}

Future<DateTime?> selectEndDate(BuildContext context) async {
  DateTime? picked = await showDatePicker(
    context: context,
    initialDate: endDate ?? DateTime.now(),
    firstDate: startDate ?? DateTime.now(),  // Prevents picking an earlier date
    lastDate: DateTime(2101),
  );

  return picked;
}

  // Check if the report can be created
  bool canCreateReport(List<String> selectedItemTypes, List<String> selectedCategories) {
    return selectedItemTypes.isNotEmpty &&
        selectedCategories.isNotEmpty &&
        startDate != null &&
        endDate != null;
  }

  // Create report logic
Future<void> createReport({
  required Uint8List barChartBytes,
  required Uint8List pieChartBytes,
  required Uint8List lineChartBytes,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final pdf = pw.Document();

  final barImage = pw.MemoryImage(barChartBytes);
  final pieImage = pw.MemoryImage(pieChartBytes);
  final lineImage = pw.MemoryImage(lineChartBytes);

  // Sayfa 1: Rapor başlığı + Bar Chart
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('BEES Data Report',
                style: pw.TextStyle(
                    fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(
                'Date Range: ${startDate.toLocal().toString().split(' ')[0]} - ${endDate.toLocal().toString().split(' ')[0]}'),
            pw.SizedBox(height: 20),
            pw.Text('Item Type Chart (Bar):'),
            pw.SizedBox(height: 10),
            pw.Transform(
              transform: Matrix4.rotationX(math.pi),
              alignment: pw.Alignment.center,
              child: pw.Image(barImage),
            ),
          ],
        );
      },
    ),
  );

  // Sayfa 2: Pie Chart
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Category Distribution (Pie Chart):',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Transform(
              transform: Matrix4.rotationX(math.pi),
              alignment: pw.Alignment.center,
              child: pw.Image(pieImage),
            ),
          ],
        );
      },
    ),
  );

  // Sayfa 3: Line Chart
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Item Trend Over Time (Line Chart):',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Transform(
              transform: Matrix4.rotationX(math.pi),
              alignment: pw.Alignment.center,
              child: pw.Image(lineImage),
            ),
          ],
        );
      },
    ),
  );

  String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

  if (selectedDirectory == null) {
    print("❌ Kullanıcı dizin seçmedi.");
    return;
  }

  // Dosyayı kaydet
  // final dir = await getApplicationDocumentsDirectory();
  // final file = File(
  //     '${dir.path}/DataReport[${startDate.toString().split(' ').first}_${endDate.toString().split(' ').first}].pdf');

  // await file.writeAsBytes(await pdf.save());

  // print('✅ PDF saved at: ${file.path}');
  final fileName = 'DataReport[${startDate.toString().split(' ').first}_${endDate.toString().split(' ').first}].pdf';
  final filePath = path.join(selectedDirectory, fileName);

  final file = File(filePath);
  await file.writeAsBytes(await pdf.save());

  print('✅ PDF saved at: $filePath');
}
  
  // Date formatting helper
  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<List<Map<String, dynamic>>> fetchFilteredItems({
  required DateTime startDate,
  required DateTime endDate,
  required List<String> selectedItemTypes,
  required List<String> selectedCategories,
}) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('beesed_items')
      .where('beesedDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('beesedDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .get();

  return snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>)
      .where((item) =>
          selectedItemTypes.contains(item['itemType']) &&
          selectedCategories.contains(item['category']))
      .toList();
}

Map<String, int> groupByField(List<Map<String, dynamic>> items, String field) {
  final Map<String, int> grouped = {};
  for (var item in items) {
    final key = item[field] ?? 'Unknown';
    if (grouped.containsKey(key)) {
      grouped[key] = grouped[key]! + 1;
    } else {
      grouped[key] = 1;
    }
  }
  return grouped;
}

Map<String, int> groupByDate(List<Map<String, dynamic>> items) {
  final Map<String, int> grouped = {};
  for (var item in items) {
    Timestamp ts = item['beesedDate'];
    DateTime dt = ts.toDate();
    String dateKey = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    grouped[dateKey] = (grouped[dateKey] ?? 0) + 1;
  }
  return grouped;
}

List<BarChartDataModel> prepareItemTypeBarChart(Map<String, int> itemTypeCounts) {
  return itemTypeCounts.entries.map((e) {
    return BarChartDataModel(label: e.key, value: e.value);
  }).toList();
}

List<LineChartDataModel> prepareDateLineChart(Map<String, int> dateCounts) {
  return dateCounts.entries.map((e) {
    return LineChartDataModel(date: e.key, count: e.value);
  }).toList();
}

List<PieChartDataModel> prepareCategoryPieChart(Map<String, int> categoryCounts) {
  return categoryCounts.entries.map((e) {
    return PieChartDataModel(label: e.key, value: e.value);
  }).toList();
}

Future<Uint8List> captureChart(GlobalKey key) async {
  RenderRepaintBoundary boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;

  ui.Image image = await boundary.toImage(pixelRatio: 3.0);
  ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}
}
