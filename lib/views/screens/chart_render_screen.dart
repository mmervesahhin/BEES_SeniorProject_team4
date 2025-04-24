import 'package:flutter/material.dart';
import 'package:bees/controllers/data_analysis_controller.dart';
import 'package:bees/views/widgets/bar_chart_widget.dart';
import 'package:bees/views/widgets/pie_chart_widget.dart';
import 'package:bees/views/widgets/line_chart_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:ui' as ui;
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/rendering.dart';

class ChartRenderScreen extends StatefulWidget {
  final Map<String, int> barChartData;
  final Map<String, int> pieChartData;
  final Map<String, int> lineChartData;
  final DateTime startDate;
  final DateTime endDate;

  const ChartRenderScreen({
    Key? key,
    required this.barChartData,
    required this.pieChartData,
    required this.lineChartData,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _ChartRenderScreenState createState() => _ChartRenderScreenState();
}

class _ChartRenderScreenState extends State<ChartRenderScreen> {
  final GlobalKey barChartKey = GlobalKey();
  final GlobalKey pieChartKey = GlobalKey();
  final GlobalKey lineChartKey = GlobalKey();
  final DataAnalysisController _controller = DataAnalysisController();
  bool isLoading = false;
  bool isGeneratingPdf = false;
  bool chartsReady = false;

  // Color scheme
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    // Allow charts to render first
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          chartsReady = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        title: Text(
          'Data Analysis Preview',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          if (!isGeneratingPdf)
            TextButton.icon(
              onPressed: () => _generatePdf(),
              icon: Icon(Icons.picture_as_pdf, color: Colors.white),
              label: Text(
                'Save PDF',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading data...',
                    style: GoogleFonts.nunito(
                      color: textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Yellow header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  color: primaryYellow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Analysis Report',
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Date Range: ${_controller.formatDate(widget.startDate)} - ${_controller.formatDate(widget.endDate)}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Charts
                Expanded(
                  child: isGeneratingPdf
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Generating PDF...',
                                style: GoogleFonts.nunito(
                                  color: textDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Please wait while we create your report',
                                style: GoogleFonts.nunito(
                                  color: textLight,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // No data message
                              if (widget.barChartData.isEmpty && 
                                  widget.pieChartData.isEmpty && 
                                  widget.lineChartData.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.bar_chart,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No data available',
                                          style: GoogleFonts.nunito(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: textDark,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Try adjusting your filters or date range',
                                          style: GoogleFonts.nunito(
                                            fontSize: 16,
                                            color: textLight,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              // Pie Chart
                              if (widget.pieChartData.isNotEmpty) ...[
                                _buildSectionHeader('Category Distribution'),
                                Container(
                                  height: 300,
                                  padding: EdgeInsets.all(16),
                                  margin: EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: CategoryPieChart(
                                    data: widget.pieChartData,
                                    repaintKey: pieChartKey,
                                  ),
                                ),
                              ],

                              // Bar Chart
                              if (widget.barChartData.isNotEmpty) ...[
                                _buildSectionHeader('Item Type Distribution'),
                                Container(
                                  height: 300,
                                  padding: EdgeInsets.all(16),
                                  margin: EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ItemTypeBarChart(
                                    data: widget.barChartData,
                                    repaintKey: barChartKey,
                                  ),
                                ),
                              ],

                              // Line Chart
                              if (widget.lineChartData.isNotEmpty) ...[
                                _buildSectionHeader('Trend Over Time'),
                                Container(
                                  height: 300,
                                  padding: EdgeInsets.all(16),
                                  margin: EdgeInsets.only(bottom: 24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ItemTrendLineChart(
                                    data: widget.lineChartData,
                                    repaintKey: lineChartKey,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ],
            ),
      bottomNavigationBar: isGeneratingPdf
          ? null
          : Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _generatePdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryYellow,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Generate PDF Report',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
      ),
    );
  }

  Future<void> _generatePdf() async {
  setState(() {
    isGeneratingPdf = true;
  });

  try {
    // Add a delay to ensure charts are fully rendered
    await Future.delayed(Duration(milliseconds: 1000));
    
    // Initialize empty byte arrays
    Uint8List barChartBytes = Uint8List(0);
    Uint8List pieChartBytes = Uint8List(0);
    Uint8List lineChartBytes = Uint8List(0);
    
    // Safely capture charts with error handling for each
    if (widget.barChartData.isNotEmpty) {
      try {
        if (barChartKey.currentContext != null) {
          barChartBytes = await _safelyCapture(barChartKey);
        }
      } catch (e) {
        print("⚠️ Bar chart capture failed: $e");
        // Continue with empty bytes
      }
    }
    
    if (widget.pieChartData.isNotEmpty) {
      try {
        if (pieChartKey.currentContext != null) {
          pieChartBytes = await _safelyCapture(pieChartKey);
        }
      } catch (e) {
        print("⚠️ Pie chart capture failed: $e");
        // Continue with empty bytes
      }
    }
    
    if (widget.lineChartData.isNotEmpty) {
      try {
        if (lineChartKey.currentContext != null) {
          lineChartBytes = await _safelyCapture(lineChartKey);
        }
      } catch (e) {
        print("⚠️ Line chart capture failed: $e");
        // Continue with empty bytes
      }
    }

    // Create PDF report with whatever data we have
    await _controller.createReport(
      barChartBytes: barChartBytes,
      pieChartBytes: pieChartBytes,
      lineChartBytes: lineChartBytes,
      barChartData: widget.barChartData,
      pieChartData: widget.pieChartData,
      lineChartData: widget.lineChartData,
      startDate: widget.startDate,
      endDate: widget.endDate,
    );

    // Return success to previous screen
    Navigator.pop(context, true);
  } catch (e) {
    print("❌ PDF generation error: $e");
    setState(() {
      isGeneratingPdf = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Error while creating PDF report. Trying alternative method...',
          style: GoogleFonts.nunito(),
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
    
    // Try alternative method without chart images
    try {
      await Future.delayed(Duration(seconds: 2));
      await _generateTextOnlyPdf();
    } catch (fallbackError) {
      print("❌ Fallback PDF generation error: $fallbackError");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create PDF report: $fallbackError',
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Helper method for safely capturing charts
Future<Uint8List> _safelyCapture(GlobalKey key) async {
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
    
    // Try with lower pixel ratio first
    final image = await boundary.toImage(pixelRatio: 2.0);
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

// Fallback method for text-only PDF
Future<void> _generateTextOnlyPdf() async {
  try {
    // Create a simple text-based report without images
    final pdf = pw.Document();
    
    // Add title page
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
                'Date Range: ${widget.startDate.toLocal().toString().split(' ')[0]} - ${widget.endDate.toLocal().toString().split(' ')[0]}',
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Data Summary (Text Only)',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              pw.Text('This is a text-only report generated because chart rendering failed.'),
            ],
          );
        },
      ),
    );
    
    // Add category data page
    if (widget.pieChartData.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Category Distribution:',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
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
                    ...widget.pieChartData.entries.map((entry) => pw.TableRow(
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
    
    // Add item type data page
    if (widget.barChartData.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Item Type Distribution:',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
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
                    ...widget.barChartData.entries.map((entry) => pw.TableRow(
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
    
    // Add trend data page
    if (widget.lineChartData.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Trend Over Time:',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Table(
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
                    ...widget.lineChartData.entries.map((entry) => pw.TableRow(
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
    
    // Get directory path for saving the PDF
    String? selectedDirectory = await _controller.getDirectoryPath();
    if (selectedDirectory == null) {
      throw Exception("No directory selected for saving the PDF");
    }
    
    final now = DateTime.now();
    final formattedNow = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    final fileName = 'TextReport[${widget.startDate.toString().split(' ').first}_${widget.endDate.toString().split(' ').first}]_$formattedNow.pdf';
    final filePath = path.join(selectedDirectory, fileName);
    
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    print('✅ Text-only PDF saved at: $filePath');
    
    // Return success to previous screen
    Navigator.pop(context, true);
  } catch (e) {
    print("❌ Text-only PDF generation error: $e");
    throw e;
  }
}
}
