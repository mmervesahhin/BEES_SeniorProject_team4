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
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Modern trading app color palette
  final Color primaryYellow = Color(0xFFFFC857);
  final Color secondaryYellow = Color(0xFFFFD166);
  final Color accentColor = Color(0xFF06D6A0);
  final Color backgroundColor = Colors.white;
  final Color cardColor = Colors.white;
  final Color textDark = Color(0xFF1F2937);
  final Color textMedium = Color(0xFF6B7280);
  final Color textLight = Color(0xFF8A8A8A);
  final Color errorColor = Color(0xFFEF4444);
  final Color successColor = Color(0xFF10B981);
  final Color borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => isLoading = true);
    List<Map<String, dynamic>> fetchedReports =
        await _adminController.fetchReportedRequests();

    for (var report in fetchedReports) {
      String? requestId = report['requestId'];
      if (requestId != null) {
        Request? req = await _requestController.getRequestById(requestId);
        if (req != null) {
          report['requestContent'] = req.requestContent;
          report['creationDate'] = req.creationDate;
          report['requestOwnerID'] = req.requestOwnerID;
          report['requestObject'] = req;

          bees.User? requestOwner =
              await _requestController.getUserByRequestID(requestId);
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

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AdminOthersUserProfileScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Request Complaints',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: primaryYellow),
            onPressed: _loadReports,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reported Requests",
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Review and manage reported requests",
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: textMedium,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryYellow),
                        ),
                      )
                    : reports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No reported requests",
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textMedium,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "There are no reported requests at this time",
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: textMedium,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: reports.length,
                            itemBuilder: (context, index) {
                              final report = reports[index];
                              return _buildReportCard(report);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: primaryYellow,
        unselectedItemColor: textLight,
        selectedLabelStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(
          fontSize: 12,
        ),
        iconSize: 22,
        elevation: 8, // shadow ekleyebilirsin
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.shop),
            label: 'Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analysis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminHomeScreen(),
              ));
              break;
            case 1:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminRequestsScreen(),
              ));
              break;
            case 2:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminReportsScreen(),
              ));
              break;
            case 3:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminDataAnalysisScreen(),
              ));
              break;
            case 4:
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => AdminProfileScreen(),
              ));
              break;
          }
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final requestOwnerName = report['requestOwnerName'] ?? 'Unknown';
    final requestOwnerSurname = report['requestOwnerSurname'] ?? '';
    final requestOwnerPhotoUrl = report['requestOwnerProfilePhoto'];
    final Request? requestObj = report['requestObject'];
    final String reportReason = report['reportReason'] ?? 'No reason provided';
    final String reporterName = report['reporterName'] ?? 'Unknown';
    final String requestContent =
        report['requestContent'] ?? 'No content available';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(report['requestOwnerID']),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: requestOwnerPhotoUrl != null
                        ? NetworkImage(requestOwnerPhotoUrl)
                        : null,
                    child: requestOwnerPhotoUrl == null
                        ? Icon(Icons.person, color: Colors.grey.shade400)
                        : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToProfile(report['requestOwnerID']),
                    child: Text(
                      '$requestOwnerName $requestOwnerSurname',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_vert, color: textDark),
                  onPressed: requestObj != null
                      ? () {
                          _adminController.showRequestRemoveOptions(
                            context,
                            requestObj,
                            onSuccess: _loadReports,
                          );
                        }
                      : null,
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                requestContent,
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: textDark,
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: errorColor.withOpacity(0.2), width: 1),
                  ),
                  child: Text(
                    reportReason,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: errorColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "Reported by: $reporterName",
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: textMedium,
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }
}
