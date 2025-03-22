import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/admin_controller.dart';
import 'package:bees/views/screens/admin_detailed_item_screen.dart'; // Import your item details screen

class ItemReportsScreen extends StatefulWidget {
  const ItemReportsScreen({super.key});

  @override
  _ItemReportsScreenState createState() => _ItemReportsScreenState();
}

class _ItemReportsScreenState extends State<ItemReportsScreen> {
  int _selectedIndex = 2;
  bool isLoading = true;
  List<Map<String, dynamic>> reports = [];
  final AdminController _adminController = AdminController();

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      List<Map<String, dynamic>> fetchedReports = await _adminController.fetchItemReports();
      setState(() {
        reports = fetchedReports;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching reports: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
        title: const Text('Item Reports', style: TextStyle(fontSize: 24, color: Colors.black)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : reports.isEmpty
                ? const Center(child: Text("No reports found"))
                : ListView.builder(
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return FutureBuilder<Map<String, dynamic>>(
                        future: _adminController.getItemDetails(report['itemId'] ?? ''),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return const Center(child: Text("Error fetching item details"));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text("Item details not found"));
                          }

                          final itemDetails = snapshot.data!;
                          final complaintDetails = report['complaintDetails'] ?? 'No complaint details provided'; // Handle complaint details

                          return GestureDetector(
                            onTap: () {
                              // Navigate to the detailed item screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AdminDetailedItemScreen(itemId: itemDetails['itemId']),
                                ),
                              );
                            },
                            child: _buildReportCard(
                              itemTitle: itemDetails['title'] ?? 'Unknown Item',
                              reportReason: report['reportReason'] ?? 'No reason provided',
                              reporterName: report['reporterName'] ?? 'Unknown',
                              photoUrl: itemDetails['photo'] ?? '',
                              complaintDetails: complaintDetails, // Pass complaint details
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 59, 137, 62),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.shop), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String itemTitle,
    required String reportReason,
    required String reporterName,
    required String photoUrl,
    required String complaintDetails, // Add complaintDetails parameter
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                  itemTitle,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text("Report Reason: $reportReason", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text("Reported by: $reporterName", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  if (complaintDetails.isNotEmpty)
                  Text("Description: $complaintDetails", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
            ),
          ],
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