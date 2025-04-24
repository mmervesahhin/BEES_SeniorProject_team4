import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/data_analysis_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bees/views/screens/chart_render_screen.dart';

class AdminDataAnalysisScreen extends StatefulWidget {
  const AdminDataAnalysisScreen({super.key});

  @override
  _AdminDataAnalysisScreenState createState() =>
      _AdminDataAnalysisScreenState();
}

class _AdminDataAnalysisScreenState extends State<AdminDataAnalysisScreen> {
  int _selectedIndex = 3;
  bool isLoading = false;
  final DataAnalysisController _controller = DataAnalysisController();

  // Color scheme
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  List<String> itemTypes = ['Books', 'Notes', 'Stationary', 'Electronics', 'Other'];
  List<String> categories = ['Sale', 'Rent', 'Exchange', 'Donate'];

  List<String> selectedItemTypes = [];
  List<String> selectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryYellow,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'BEES Admin',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              _showHelpDialog();
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryYellow,
        unselectedItemColor: textLight,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.shop), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Complaints'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
      body: Column(
        children: [
          // Yellow header
          Container(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
            decoration: BoxDecoration(
              color: primaryYellow,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Analysis',
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Generate reports based on user activity and item data',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Section
                  Text(
                    'SELECT DATE RANGE',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await _controller.selectStartDate(context);
                            if (date != null) {
                              setState(() {
                                _controller.startDate = date;
                              });
                            }
                          },
                          child: _buildDatePickerField('Start Date', _controller.startDate),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await _controller.selectEndDate(context);
                            if (date != null) {
                              setState(() {
                                _controller.endDate = date;
                              });
                            }
                          },
                          child: _buildDatePickerField('End Date', _controller.endDate),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Item Type Filter
                  Text(
                    'SELECT ITEM TYPES',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: itemTypes.map((itemType) {
                      final isSelected = selectedItemTypes.contains(itemType);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedItemTypes.remove(itemType);
                            } else {
                              selectedItemTypes.add(itemType);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryYellow : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected ? primaryYellow : Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryYellow.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            itemType,
                            style: GoogleFonts.nunito(
                              color: isSelected ? Colors.white : textDark,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24),
                  
                  // Category Filter
                  Text(
                    'SELECT CATEGORIES',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textLight,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      final isSelected = selectedCategories.contains(category);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedCategories.remove(category);
                            } else {
                              selectedCategories.add(category);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryYellow : Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: isSelected ? primaryYellow : Colors.grey.withOpacity(0.3),
                              width: 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: primaryYellow.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            category,
                            style: GoogleFonts.nunito(
                              color: isSelected ? Colors.white : textDark,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 32),
                  
                  // Create Report Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _controller.canCreateReport(selectedItemTypes, selectedCategories)
                            ? () async {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  // Fetch filtered data from Firestore
                                  final items = await _controller.fetchFilteredItems(
                                    startDate: _controller.startDate!,
                                    endDate: _controller.endDate!,
                                    selectedItemTypes: selectedItemTypes,
                                    selectedCategories: selectedCategories,
                                  );
                                  
                                  // Group data for charts
                                  final barChartData = _controller.groupByField(items, 'itemType');
                                  final pieChartData = _controller.groupByField(items, 'category');
                                  final lineChartData = _controller.groupByDate(items);

                                  // Navigate to the chart render screen
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChartRenderScreen(
                                        barChartData: barChartData,
                                        pieChartData: pieChartData,
                                        lineChartData: lineChartData,
                                        startDate: _controller.startDate!,
                                        endDate: _controller.endDate!,
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'PDF report created successfully!',
                                          style: GoogleFonts.nunito(),
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print("❌ Data processing error: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error while processing data: $e',
                                        style: GoogleFonts.nunito(),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                              }
                            : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryYellow,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey.withOpacity(0.5),
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Processing Data...',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'Generate Report',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Info text
                  if (!_controller.canCreateReport(selectedItemTypes, selectedCategories))
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: lightYellow.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryYellow.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: primaryYellow),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Please select date range, at least one item type, and at least one category to generate a report.',
                              style: GoogleFonts.nunito(
                                color: textDark,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField(String label, DateTime? date) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: textLight,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: primaryYellow),
              SizedBox(width: 8),
              Text(
                date == null ? 'Select Date' : _controller.formatDate(date),
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: date == null ? textLight : textDark,
                  fontWeight: date == null ? FontWeight.normal : FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Data Analysis Help',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: primaryYellow,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem(
              icon: Icons.calendar_today,
              title: 'Date Range',
              description: 'Select start and end dates to analyze data within that period.',
            ),
            SizedBox(height: 16),
            _buildHelpItem(
              icon: Icons.category,
              title: 'Item Types',
              description: 'Choose which item types to include in your analysis.',
            ),
            SizedBox(height: 16),
            _buildHelpItem(
              icon: Icons.sell,
              title: 'Categories',
              description: 'Select which transaction categories to analyze.',
            ),
            SizedBox(height: 16),
            _buildHelpItem(
              icon: Icons.picture_as_pdf,
              title: 'PDF Report',
              description: 'The generated report includes charts and AI-powered insights.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: GoogleFonts.nunito(
                color: primaryYellow,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: lightYellow,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: primaryYellow),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textDark,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: textLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminHomeScreen()));
        break;
      case 1:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminRequestsScreen()));
        break;
      case 2:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminReportsScreen()));
        break;
      case 3:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminDataAnalysisScreen()));
        break;
      case 4:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminProfileScreen()));
        break;
    }
  }
}
