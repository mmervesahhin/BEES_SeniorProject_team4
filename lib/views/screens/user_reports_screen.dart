import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  _UserReportsScreenState createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  int _selectedIndex = 2;
  bool isLoading = false; // Change to false when loading is done

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'User Reports',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  
                ],
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
    );
  }

  Widget _buildReportCard({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8, // Enhanced shadow for better depth
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Increase padding for more spacious feel
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align text and icon
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20, // Increase font size for better readability
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Icon(Icons.arrow_forward, color: Color.fromARGB(255, 59, 137, 62)), // Add icon for interaction hint
            ],
          ),
        ),
      ),
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