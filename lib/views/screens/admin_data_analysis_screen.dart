import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/data_analysis_controller.dart';

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

  List<String> itemTypes = ['Books', 'Notes', 'Stationery', 'Electronics', 'Others'];
  List<String> categories = ['Sale', 'Rent', 'Exchange', 'Donation'];

  List<String> selectedItemTypes = [];
  List<String> selectedCategories = [];

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
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
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
              onPressed: _controller.canCreateReport(selectedItemTypes, selectedCategories) ? _controller.createReport : null,
              child: isLoading
                  ? CircularProgressIndicator(
                      color: const Color.fromARGB(255, 255, 255, 255),
                    )
                  : Text('Create Report',  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
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
