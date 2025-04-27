import 'package:flutter/material.dart';
import 'package:bees/controllers/data_analysis_controller.dart';
import 'package:bees/views/widgets/bar_chart_widget.dart';
import 'package:bees/views/widgets/pie_chart_widget.dart';
import 'package:bees/views/widgets/line_chart_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
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
  bool isGeneratingPdf = false;

  final Color primaryYellow = Color(0xFFFFC857);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        title: Text(
          'Data Analysis Report',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isGeneratingPdf
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),

                  SizedBox(height: 24),

                  // Pie Chart
                  if (widget.pieChartData.isNotEmpty) ...[
                    _buildSectionTitle('Category Distribution'),
                    Container(
                      key: pieChartKey,
                      padding: EdgeInsets.all(16),
                      decoration: _chartBoxDecoration(),
                      child: CategoryPieChart(
                        data: widget.pieChartData,
                        repaintKey: pieChartKey,
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Bar Chart
                  if (widget.barChartData.isNotEmpty) ...[
                    _buildSectionTitle('Item Type Distribution'),
                    Container(
                      key: barChartKey,
                      padding: EdgeInsets.all(16),
                      decoration: _chartBoxDecoration(),
                      child: ItemTypeBarChart(
                        data: widget.barChartData,
                        repaintKey: barChartKey,
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Line Chart
                  if (widget.lineChartData.isNotEmpty) ...[
                    _buildSectionTitle('Trend Over Time'),
                    Container(
                      key: lineChartKey,
                      padding: EdgeInsets.all(16),
                      decoration: _chartBoxDecoration(),
                      child: ItemTrendLineChart(
                        data: widget.lineChartData,
                        repaintKey: lineChartKey,
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  SizedBox(height: 32),

                  Center(
                    child: ElevatedButton(
                      onPressed: _generatePdf,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Generate PDF Report',
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range:',
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '${_controller.formatDate(widget.startDate)} - ${_controller.formatDate(widget.endDate)}',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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

  BoxDecoration _chartBoxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  Future<void> _generatePdf() async {
    setState(() {
      isGeneratingPdf = true;
    });

    try {
      // 🆕 Charts tam render edilsin diye frame bekliyoruz
      await Future.delayed(Duration.zero);
      await WidgetsBinding.instance.endOfFrame;

      Uint8List pieChartBytes = Uint8List(0);
      Uint8List barChartBytes = Uint8List(0);
      Uint8List lineChartBytes = Uint8List(0);

      if (pieChartKey.currentContext != null) {
        pieChartBytes = await _captureChart(pieChartKey);
      }
      if (barChartKey.currentContext != null) {
        barChartBytes = await _captureChart(barChartKey);
      }
      if (lineChartKey.currentContext != null) {
        lineChartBytes = await _captureChart(lineChartKey);
      }

      await _controller.createReport(
        pieChartBytes: pieChartBytes,
        barChartBytes: barChartBytes,
        lineChartBytes: lineChartBytes,
        barChartData: widget.barChartData,
        pieChartData: widget.pieChartData,
        lineChartData: widget.lineChartData,
        startDate: widget.startDate,
        endDate: widget.endDate,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('❌ Error while generating PDF: $e');
      setState(() {
        isGeneratingPdf = false;
      });
    }
  }

  Future<Uint8List> _captureChart(GlobalKey key) async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
