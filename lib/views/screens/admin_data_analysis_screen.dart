import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/data_analysis_controller.dart';
import 'package:bees/views/widgets/bar_chart_widget.dart';
import 'package:bees/views/widgets/pie_chart_widget.dart';
import 'package:bees/views/widgets/line_chart_widget.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDataAnalysisScreen extends StatefulWidget {
  const AdminDataAnalysisScreen({super.key});

  @override
  _AdminDataAnalysisScreenState createState() =>
      _AdminDataAnalysisScreenState();
}

class _AdminDataAnalysisScreenState extends State<AdminDataAnalysisScreen> {
  final GlobalKey barChartKey = GlobalKey();
  final GlobalKey pieChartKey = GlobalKey();
  final GlobalKey lineChartKey = GlobalKey();
  int _selectedIndex = 3;
  bool isLoading = false;
  final DataAnalysisController _controller = DataAnalysisController();
  String? selectedQuickOption;
  // Color scheme
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  List<String> itemTypes = [
    'Books',
    'Notes',
    'Stationary',
    'Electronics',
    'Other'
  ];
  List<String> categories = ['Sale', 'Rent', 'Exchange', 'Donate'];

  List<String> selectedItemTypes = [];
  List<String> selectedCategories = [];

  Map<String, int> pieChartData = {};
  Map<String, int> barChartData = {};
  Map<String, int> lineChartData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'BEES ',
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryYellow,
                    ),
                  ),
                  TextSpan(
                    text: 'admin',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryYellow,
        unselectedItemColor: textLight,
        backgroundColor: Colors.white,
        elevation: 8,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.nunito(),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.shop), label: 'Items'),
          BottomNavigationBarItem(
              icon: Icon(Icons.assignment), label: 'Requests'),
          BottomNavigationBarItem(
              icon: Icon(Icons.report), label: 'Complaints'),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: 'Analysis'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Data Analysis Report',
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Select filters and generate reports with visualized data',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: textLight,
                ),
              ),
              SizedBox(height: 24),

              // Date Range Filter - Enhanced
              Container(
                padding: EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.date_range, color: primaryYellow),
                        SizedBox(width: 8),
                        Text(
                          'Date Range',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _controller.selectStartDate(context),
                            child: _buildDatePickerField(
                                'Start Date', _controller.startDate),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _controller.selectEndDate(context),
                            child: _buildDatePickerField(
                                'End Date', _controller.endDate),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Quick date selection buttons
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Quick Select:',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: textLight,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        _buildQuickDateButton('Today'),
                        SizedBox(width: 8),
                        _buildQuickDateButton('This Week'),
                        SizedBox(width: 8),
                        _buildQuickDateButton('This Month'),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Filters Container - Enhanced
              Container(
                padding: EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.filter_list, color: primaryYellow),
                        SizedBox(width: 8),
                        Text(
                          'Filters',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                        Spacer(),
                        // Reset filters button
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              selectedItemTypes.clear();
                              selectedCategories.clear();
                            });
                          },
                          icon: Icon(Icons.refresh, size: 16),
                          label: Text(
                            'Reset',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: textLight,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Item Type Filter
                    Text(
                      'Item Type',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 5,
                      children: itemTypes.map((itemType) {
                        return FilterChip(
                          label: Text(
                            itemType,
                            style: GoogleFonts.nunito(
                              color: selectedItemTypes.contains(itemType)
                                  ? Colors.white
                                  : textDark,
                              fontWeight: selectedItemTypes.contains(itemType)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: selectedItemTypes.contains(itemType),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedItemTypes.add(itemType);
                              } else {
                                selectedItemTypes.remove(itemType);
                              }
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: primaryYellow,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: selectedItemTypes.contains(itemType)
                                  ? primaryYellow
                                  : Colors.grey.shade300,
                            ),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          elevation:
                              selectedItemTypes.contains(itemType) ? 1 : 0,
                          shadowColor: selectedItemTypes.contains(itemType)
                              ? primaryYellow.withOpacity(0.3)
                              : Colors.transparent,
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20),

                    // Category Filter
                    Text(
                      'Category',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: categories.map((category) {
                        return FilterChip(
                          label: Text(
                            category,
                            style: GoogleFonts.nunito(
                              color: selectedCategories.contains(category)
                                  ? Colors.white
                                  : textDark,
                              fontWeight: selectedCategories.contains(category)
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: selectedCategories.contains(category),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                selectedCategories.add(category);
                              } else {
                                selectedCategories.remove(category);
                              }
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: primaryYellow,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: selectedCategories.contains(category)
                                  ? primaryYellow
                                  : Colors.grey.shade300,
                            ),
                          ),
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          elevation:
                              selectedCategories.contains(category) ? 2 : 0,
                          shadowColor: selectedCategories.contains(category)
                              ? primaryYellow.withOpacity(0.3)
                              : Colors.transparent,
                        );
                      }).toList(),
                    ),

                    SizedBox(height: 20),

                    // Filter status summary
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: textLight, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selectedItemTypes.isEmpty &&
                                      selectedCategories.isEmpty
                                  ? 'No filters selected.'
                                  : 'Filters: ${selectedItemTypes.length} item types, ${selectedCategories.length} categories selected',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Create Report Button - Enhanced
              ElevatedButton.icon(
                onPressed: _controller.canCreateReport(
                        selectedItemTypes, selectedCategories)
                    ? () async {
                        setState(() {
                          isLoading = true;
                        });

                        try {
                          print('⏳ Start Date: ${_controller.startDate}');
                          print('⏳ End Date: ${_controller.endDate}');

                          final items = await _controller.fetchFilteredItems(
                            startDate: _controller.startDate!,
                            endDate: _controller.endDate!,
                            selectedItemTypes: selectedItemTypes,
                            selectedCategories: selectedCategories,
                          );

                          // Group data
                          barChartData =
                              _controller.groupByField(items, 'itemType');
                          pieChartData =
                              _controller.groupByField(items, 'category');
                          lineChartData = _controller.groupByDate(items);

                          // Redraw charts
                          setState(() {});

                          // Wait for charts to render
                          await Future.delayed(Duration(milliseconds: 300));

                          // Capture charts
                          final pieBytes =
                              await _controller.captureChart(pieChartKey);
                          final barChartBytes =
                              await _controller.captureChart(barChartKey);
                          final lineBytes =
                              await _controller.captureChart(lineChartKey);

                          // Create PDF
                          await _controller.createReport(
                            barChartBytes: barChartBytes,
                            pieChartBytes: pieBytes,
                            lineChartBytes: lineBytes,
                            barChartData: barChartData,
                            pieChartData: pieChartData,
                            lineChartData: lineChartData,
                            startDate: _controller.startDate!,
                            endDate: _controller.endDate!,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'PDF report created successfully!',
                                style: GoogleFonts.nunito(),
                              ),
                              backgroundColor: primaryYellow,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          print("❌ Chart capture or PDF error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error while creating report.',
                                style: GoogleFonts.nunito(),
                              ),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    : null,
                icon: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(Icons.bar_chart, color: backgroundColor),
                label: Text(
                  'Generate Report',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryYellow,
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  minimumSize: Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 40),

              // Charts Preview Section - Enhanced
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bar_chart, color: primaryYellow),
                        SizedBox(width: 8),
                        Text(
                          'Charts Preview',
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),

                    // Pie Chart
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.pie_chart,
                                  color: primaryYellow, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Category Distribution',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 350,
                            child: CategoryPieChart(
                                data: pieChartData, repaintKey: pieChartKey),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Bar Chart
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bar_chart,
                                  color: primaryYellow, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Item Type Distribution',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 250,
                            child: ItemTypeBarChart(
                                data: barChartData, repaintKey: barChartKey),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Line Chart
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.show_chart,
                                  color: primaryYellow, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Item Trend Over Time',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Container(
                            height: 250,
                            child: ItemTrendLineChart(
                                data: lineChartData, repaintKey: lineChartKey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDateButton(String label) {
    bool isSelected = selectedQuickOption == label;

    return OutlinedButton(
      onPressed: () {
        // If already selected, deselect it
        if (isSelected) {
          setState(() {
            selectedQuickOption = null;
            _controller.startDate = null;
            _controller.endDate = null;
          });
          return;
        }

        // Set date range based on label
        DateTime now = DateTime.now();
        DateTime startDate;
        DateTime endDate = now;

        if (label == 'Today') {
          startDate = DateTime(now.year, now.month, now.day);
        } else if (label == 'This Week') {
          startDate = now.subtract(Duration(days: now.weekday - 1));
        } else if (label == 'This Month') {
          startDate = DateTime(now.year, now.month, 1);
        } else {
          startDate = now;
        }

        setState(() {
          _controller.startDate = startDate;
          _controller.endDate = endDate;
          selectedQuickOption = label;
        });
      },
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isSelected ? primaryYellow : textLight,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? primaryYellow : textLight,
        side: BorderSide(
          color: isSelected ? primaryYellow : Colors.grey.shade300,
        ),
        backgroundColor:
            isSelected ? lightYellow.withOpacity(0.2) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: Size(0, 30),
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime? date) {
    return TextField(
      controller: TextEditingController(
        text: date == null ? '' : _controller.formatDate(date),
      ),
      readOnly: true,
      style: GoogleFonts.nunito(
        color: textDark,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.nunito(color: textLight),
        suffixIcon: Icon(Icons.calendar_today, color: primaryYellow),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryYellow, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onTap: () async {
        // Clear quick selection when manually picking a date
        setState(() {
          selectedQuickOption = null;
        });

        DateTime? selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: primaryYellow,
                  onPrimary: Colors.white,
                  onSurface: textDark,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: primaryYellow,
                  ),
                ),
              ),
              child: child!,
            );
          },
        );

        if (selectedDate != null) {
          DateTime turkeyTime = selectedDate.toUtc().add(Duration(hours: 3));

          setState(() {
            if (label == 'End Date' &&
                _controller.startDate != null &&
                turkeyTime.isBefore(_controller.startDate!)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'End date cannot be before start date.',
                    style: GoogleFonts.nunito(),
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              if (label == 'Start Date') {
                _controller.startDate = turkeyTime;
                if (_controller.endDate != null &&
                    _controller.endDate!.isBefore(turkeyTime)) {
                  _controller.endDate = null;
                }
              } else {
                _controller.endDate = turkeyTime;
              }
            }
          });
        }
      },
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AdminHomeScreen()));
        break;
      case 1:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AdminRequestsScreen()));
        break;
      case 2:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AdminReportsScreen()));
        break;
      case 3:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AdminDataAnalysisScreen()));
        break;
      case 4:
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => AdminProfileScreen()));
        break;
    }
  }
}
