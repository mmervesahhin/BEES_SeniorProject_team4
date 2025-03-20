import 'package:bees/controllers/admin_controller.dart';
import 'package:bees/controllers/request_controller.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/models/user_model.dart' as bees;
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_others_user_profile_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:bees/views/screens/others_user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestReportsScreen extends StatefulWidget {
  const RequestReportsScreen({super.key});

  @override
  _RequestReportsScreenState createState() => _RequestReportsScreenState();
}

class _RequestReportsScreenState extends State<RequestReportsScreen> {
  int _selectedIndex = 2;
  bool isLoading = true;
  List<Map<String, dynamic>> reports = [];
  final RequestController _requestController = RequestController();
  final AdminController _adminController = AdminController();
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => isLoading = true);
    List<Map<String, dynamic>> fetchedReports = await _adminController.fetchReportedRequests();

    for (var report in fetchedReports) {
      String? requestId = report['requestId'];
      if (requestId != null) {
        Request? req = await _requestController.getRequestById(requestId);
        if (req != null) {
          report['requestContent'] = req.requestContent;
          report['creationDate'] = req.creationDate;
          report['requestOwnerID'] = req.requestOwnerID;
          report['requestObject'] = req;

          bees.User? requestOwner = await _requestController.getUserByRequestID(requestId);
          if (requestOwner != null) {
            report['requestOwnerName'] = requestOwner.firstName;
            report['requestOwnerSurname'] = requestOwner.lastName;
            report['requestOwnerProfilePhoto'] = requestOwner.profilePicture;
          }
        }
      }
    }

    setState(() {
      reports = fetchedReports;
      isLoading = false;
    });
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

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminOthersUserProfileScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
        title: const Text(
          'Request Reports',
          style: TextStyle(fontSize: 24, color: Colors.black),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? const Center(child: Text("No reported requests found"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return _buildReportCard(report);
                  },
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

  Widget _buildReportCard(Map<String, dynamic> report) {
    final requestOwnerName = report['requestOwnerName'] ?? 'Unknown';
    final requestOwnerSurname = report['requestOwnerSurname'] ?? '';
    final requestOwnerPhotoUrl = report['requestOwnerProfilePhoto'];
    final Request? requestObj = report['requestObject'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(report['requestOwnerID']),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundImage: requestOwnerPhotoUrl != null
                        ? NetworkImage(requestOwnerPhotoUrl)
                        : const AssetImage('assets/default_profile.png') as ImageProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToProfile(report['requestOwnerID']),
                    child: Text(
                      '$requestOwnerName $requestOwnerSurname',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onPressed: requestObj != null
                      ? () {
                          _adminController.showRequestRemoveOptions(
                            context,
                            requestObj,
                            onSuccess: _loadReports, // <-- reload reports automatically
                          );
                        }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("${report['requestContent']}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              "Report Reason: ${report['reportReason'] ?? 'No reason provided'}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              "Reported by: ${report['reporterName'] ?? 'Unknown'}",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }
}
