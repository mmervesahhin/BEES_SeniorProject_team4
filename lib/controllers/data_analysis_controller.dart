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
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  required Map<String, int> barChartData,
  required Map<String, int> pieChartData,
  required Map<String, int> lineChartData,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  if (barChartData.isEmpty && pieChartData.isEmpty && lineChartData.isEmpty) {
    // No data case - unchanged
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('BEES Data Report',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text(
                'Date Range: ${startDate.toLocal().toString().split(' ')[0]} - ${endDate.toLocal().toString().split(' ')[0]}',
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'No data available for the selected filters in this date range.',
                style: pw.TextStyle(fontSize: 16, fontStyle: pw.FontStyle.italic),
              ),
            ],
          );
        },
      ),
    );

    // Get directory path for saving the PDF
    String? selectedDirectory = await getDirectoryPath();
    if (selectedDirectory == null) {
      throw Exception("No directory selected for saving the PDF");
    }

    final now = DateTime.now();
    final formattedTime = '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    final formattedStart = '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
    final formattedEnd = '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
    final fileName = 'DataReport[${formattedStart}_to_${formattedEnd}]_at_$formattedTime.pdf';
    final filePath = path.join(selectedDirectory, fileName);

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    print('✅ PDF saved with no-data message at: $filePath');
    return; // ⛔ STOP processing, don't continue
  }

  final pdf = pw.Document();
  
  // AI Prompt generation
  final aiPrompt = generateAIPrompt(
    itemTypeData: barChartData,
    categoryData: pieChartData,
    trendData: lineChartData,
  );

  // AI summary fetch
  String? aiResponse;
  try {
    aiResponse = await fetchAISummaryFromFunction(aiPrompt);
    print("🧠 AI Prompt:\n$aiPrompt");
    print("🤖 AI Response from server: $aiResponse");
  } catch (e) {
    print("⚠️ Failed to fetch AI summary: $e");
    aiResponse = "Unable to generate AI summary at this time.";
  }

  // Title page
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('BEES Data Report',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text(
                'Date Range: ${startDate.toLocal().toString().split(' ')[0]} - ${endDate.toLocal().toString().split(' ')[0]}'),
            pw.SizedBox(height: 20),
          ],
        );
      },
    ),
  );

  // Category Distribution (Pie Chart)
  if (pieChartData.isNotEmpty) {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Category Distribution:',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              
              // Add image if available, otherwise add table
              pieChartBytes.isNotEmpty 
                ? pw.Image(pw.MemoryImage(pieChartBytes))
                : pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text('Count', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...pieChartData.entries.map((entry) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(entry.key),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(entry.value.toString()),
                          ),
                        ],
                      )).toList(),
                    ],
                  ),
            ],
          );
        },
      ),
    );
  }

  // Item Type Distribution (Bar Chart)
  if (barChartData.isNotEmpty) {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Item Type Distribution:',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              
              // Add image if available, otherwise add table
              barChartBytes.isNotEmpty 
                ? pw.Image(pw.MemoryImage(barChartBytes))
                : pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text('Item Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text('Count', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...barChartData.entries.map((entry) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(entry.key),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(entry.value.toString()),
                          ),
                        ],
                      )).toList(),
                    ],
                  ),
            ],
          );
        },
      ),
    );
  }

  // Trend Over Time (Line Chart)
  if (lineChartData.isNotEmpty) {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Trend Over Time:',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              
              // Add image if available, otherwise add table
              lineChartBytes.isNotEmpty 
                ? pw.Image(pw.MemoryImage(lineChartBytes))
                : pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text('Count', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                        ],
                      ),
                      ...lineChartData.entries.map((entry) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(entry.key),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8),
                            child: pw.Text(entry.value.toString()),
                          ),
                        ],
                      )).toList(),
                    ],
                  ),
            ],
          );
        },
      ),
    );
  }

  // AI Summary
  if (aiResponse != null && aiResponse.isNotEmpty) {
    final summaryChunks = splitTextToFitPages(aiResponse);
    for (var chunk in summaryChunks) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('AI Generated Summary',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text(chunk, style: const pw.TextStyle(fontSize: 12)),
              ],
            );
          },
        ),
      );
    }
  }

  // Get directory path for saving the PDF
  String? selectedDirectory = await getDirectoryPath();
  
  if (selectedDirectory == null) {
    throw Exception("No directory selected for saving the PDF");
  }

  final now = DateTime.now();
  final formattedNow = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
  final fileName = 'DataReport[${startDate.toString().split(' ').first}_${endDate.toString().split(' ').first}]_$formattedNow.pdf';
  final filePath = path.join(selectedDirectory, fileName);

  final file = File(filePath);
  await file.writeAsBytes(await pdf.save());

  print('✅ PDF saved at: $filePath');
}

// Helper method to get directory path with retry logic
Future<String?> getDirectoryPath() async {
  String? selectedDirectory;
  int attempts = 0;
  const maxAttempts = 3;
  
  while (selectedDirectory == null && attempts < maxAttempts) {
    attempts++;
    try {
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null && attempts < maxAttempts) {
        // Wait a moment before retrying
        await Future.delayed(Duration(milliseconds: 500));
      }
    } catch (e) {
      print("❌ Error selecting directory (attempt $attempts): $e");
      if (attempts < maxAttempts) {
        // Wait a moment before retrying
        await Future.delayed(Duration(milliseconds: 500));
      }
    }
  }
  
  return selectedDirectory;
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
 String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

// Update the captureChart method to be more robust
Future<Uint8List> captureChart(GlobalKey key) async {
  try {
    if (key.currentContext == null) {
      print("⚠️ Chart context is null");
      return Uint8List(0);
    }
    
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      print("⚠️ RenderRepaintBoundary is null");
      return Uint8List(0);
    }
    
    // Try with progressively lower pixel ratios if needed
    ui.Image? image;
    for (double ratio in [1.5, 1.0]) {
      try {
        image = await boundary.toImage(pixelRatio: ratio);
        break; // If successful, break the loop
      } catch (e) {
        print("⚠️ Failed to capture with pixel ratio $ratio: $e");
        // Continue to next ratio
      }
    }
    
    if (image == null) {
      print("⚠️ Failed to capture image with any pixel ratio");
      return Uint8List(0);
    }
    
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      print("⚠️ ByteData is null");
      return Uint8List(0);
    }
    
    return byteData.buffer.asUint8List();
  } catch (e) {
    print("⚠️ Chart capture error: $e");
    return Uint8List(0);
  }
}


String generateAIPrompt({
  required Map<String, int> itemTypeData,
  required Map<String, int> categoryData,
  required Map<String, int> trendData,
}) {
  String itemTypeJson = jsonEncode(itemTypeData);
  String categoryJson = jsonEncode(categoryData);
  String trendJson = jsonEncode(trendData);

  return '''
Analyze the following datasets extracted from BEES, a university material exchange platform. Identify key patterns, outliers, and relevant administrative insights.

Item Types and Quantities:
$itemTypeJson

Categories (e.g., Sale, Donation):
$categoryJson

Time-based Trends (daily beesed count):
$trendJson

Provide a brief analytical summary of the trends observed above, tailored for university administrators to understand student material needs and usage behaviors. Please do not use bolds but reorganize in a different way like using numbers.
''';
}

Future<String?> fetchAISummaryFromFunction(String prompt) async {
  const endpoint = 'https://bees-ai-summary-819551270360.us-central1.run.app';

  try {
    final response = await http.post(
      Uri.parse(endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json.containsKey('summary') && json['summary'] is String && json['summary'].trim().isNotEmpty) {
        return json['summary'];
      } else {
        print('⚠️ AI responded but no summary in response: $json');
        return null;
      }
    } else {
      print('❌ AI API error: ${response.statusCode} ${response.body}');
      return null;
    }
  } catch (e) {
    print('❌ HTTP request failed: $e');
    return null;
  }
}

List<String> splitTextToFitPages(String text, {int chunkSize = 2000}) {
  List<String> chunks = [];
  for (var i = 0; i < text.length; i += chunkSize) {
    int end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
    chunks.add(text.substring(i, end));
  }
  return chunks;
}

}
