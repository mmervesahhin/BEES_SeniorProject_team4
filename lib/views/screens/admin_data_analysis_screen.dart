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

class AdminDataAnalysisScreen extends StatefulWidget {
  const AdminDataAnalysisScreen({super.key});

  @override
  _AdminDataAnalysisScreenState createState() =>
      _AdminDataAnalysisScreenState();

      
}


class _AdminDataAnalysisScreenState extends State<AdminDataAnalysisScreen> {
  
  // final GlobalKey barChartKey = GlobalKey(); //data analysis için deneme
  // final GlobalKey pieChartKey = GlobalKey(); //data analysis için deneme
  // final GlobalKey lineChartKey = GlobalKey(); //data analysis için deneme
  final GlobalKey barChartKey = GlobalKey(); //data analysis için deneme
  final GlobalKey pieChartKey = GlobalKey(); //data analysis için deneme
  final GlobalKey lineChartKey = GlobalKey(); //data analysis için deneme
  int _selectedIndex = 3;
  bool isLoading = false;
  final DataAnalysisController _controller = DataAnalysisController();

  List<String> itemTypes = ['Books', 'Notes', 'Stationary', 'Electronics', 'Other'];
  List<String> categories = ['Sale', 'Rent', 'Exchange', 'Donate'];

  List<String> selectedItemTypes = [];
  List<String> selectedCategories = [];

//   final Map<String, int> dummyBarData = {
//   'Books': 12,
//   'Notes': 8,
//   'Stationery': 15,
//   'Electronics': 6,
//   'Others': 4,
// };

// final Map<String, int> dummyPieData = {
//   'Sale': 10,
//   'Donation': 6,
//   'Exchange': 3,
//   'Rent': 1,
// };

// final Map<String, int> dummyLineData = {
//   '2025-03-01': 2,
//   '2025-03-02': 4,
//   '2025-03-03': 3,
//   '2025-03-04': 7,
// };
Map<String, int> pieChartData = {};
Map<String, int> barChartData = {};
Map<String, int> lineChartData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
        automaticallyImplyLeading: false,
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'BEES ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                ),
              ),
              TextSpan(
                text: 'admin',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.yellow,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 59, 137, 62),
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
      body: Padding(
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Data Analysis Report',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            // Date Range Filter
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _controller.selectStartDate(context),
                    child: _buildDatePickerField('Start Date', _controller.startDate),
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _controller.selectEndDate(context),
                    child: _buildDatePickerField('End Date', _controller.endDate),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            // Item Type Filter
            Text('Item Type'),
            Wrap(
              spacing: 10,
              children: itemTypes.map((itemType) {
                return FilterChip(
                  label: Text(itemType),
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
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Category Filter
            Text('Category'),
            Wrap(
              spacing: 10,
              children: categories.map((category) {
                return FilterChip(
                  label: Text(category),
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
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            // Create Report Button
            ElevatedButton(
              onPressed: _controller.canCreateReport(selectedItemTypes, selectedCategories)
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

                      // Veriyi grupla
                      barChartData = _controller.groupByField(items, 'itemType');
                      pieChartData = _controller.groupByField(items, 'category');
                      lineChartData = _controller.groupByDate(items);

                      // 📌 Grafik verisi geldi, grafikleri ekranda yeniden çizdirelim:
                      setState(() {});

                      // ⏳ Grafiklerin ekranda çizilmesini bekleyelim:
                      await Future.delayed(Duration(milliseconds: 300));  // ⭐️ BU YENİ

                      // 📸 Şimdi güvenle capture yapabiliriz
                      final pieBytes = await _controller.captureChart(pieChartKey);
                      final barChartBytes = await _controller.captureChart(barChartKey);
                      final lineBytes = await _controller.captureChart(lineChartKey);

                      // PDF oluştur
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
                            SnackBar(content: Text('PDF report created successfully!')),
                          );
                        } catch (e) {
                          print("❌ Chart capture or PDF error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error while creating report.')),
                          );
                        } finally {
                          setState(() {
                            isLoading = false;
                          });
                        }
                      }
                    : null,

              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Create Report', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 40), // Biraz boşluk verelim

            Text(
              'Charts Preview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10),

            CategoryPieChart(data: pieChartData, repaintKey: pieChartKey),
            SizedBox(height: 20),
            ItemTypeBarChart(data: barChartData, repaintKey: barChartKey),
            SizedBox(height: 20),
            ItemTrendLineChart(data: lineChartData, repaintKey: lineChartKey),
          ],
        ),
      ),
    ),
    );
  }

Widget _buildDatePickerField(String label, DateTime? date) {
  return TextField(
    controller: TextEditingController(
      text: date == null ? '' : _controller.formatDate(date),
    ),
    readOnly: true,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: Icon(Icons.calendar_today),
      border: OutlineInputBorder(),
    ),
    onTap: () async {
      DateTime? selectedDate = await showDatePicker(
        context: context,
        initialDate: date ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );

      if (selectedDate != null) {
        // Convert to Turkey time zone (UTC+3)
        DateTime turkeyTime = selectedDate.toUtc().add(Duration(hours: 3));

        setState(() {
          if (label == 'End Date' && _controller.startDate != null && turkeyTime.isBefore(_controller.startDate!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('End date cannot be before start date.')),
            );
          } else {
            if (label == 'Start Date') {
              _controller.startDate = turkeyTime;

              if (_controller.endDate != null && _controller.endDate!.isBefore(turkeyTime)) {
                _controller.endDate = null; // Reset end date
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
