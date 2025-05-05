import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/admin_controller.dart';
import 'package:bees/views/screens/admin_detailed_item_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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

  // Modern trading app color palette
  final Color primaryYellow = Color(0xFFFFC857);
  final Color secondaryYellow = Color(0xFFFFD166);
  final Color accentColor = Color(0xFF06D6A0);
  final Color backgroundColor = Colors.white;
  final Color cardColor = Colors.white;
  final Color textDark = Color(0xFF1F2937);
  final Color textMedium = Color(0xFF6B7280);
  final textLight = Color(0xFF8A8A8A);
  final Color errorColor = Color(0xFFEF4444);
  final Color successColor = Color(0xFF10B981);
  final Color borderColor = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      List<Map<String, dynamic>> fetchedReports =
          await _adminController.fetchItemReports();
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
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: textDark, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Item Complaints',
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
              onPressed: () {
                setState(() {
                  isLoading = true;
                });
                _fetchReports();
              },
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
                  "Reported Items",
                  style: GoogleFonts.nunito(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Review and manage reported items",
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
                                    "No reports found",
                                    style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textMedium,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "There are no reported items at this time",
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
                                return FutureBuilder<Map<String, dynamic>>(
                                  future: _adminController
                                      .getItemDetails(report['itemId'] ?? ''),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return _buildLoadingCard();
                                    }

                                    if (snapshot.hasError) {
                                      return _buildErrorCard(
                                          "Error fetching item details");
                                    }

                                    if (!snapshot.hasData ||
                                        snapshot.data!.isEmpty) {
                                      return _buildErrorCard(
                                          "Item details not found");
                                    }

                                    final itemDetails = snapshot.data!;
                                    final complaintDetails =
                                        report['complaintDetails'] ??
                                            'No complaint details provided';

                                    return _buildReportCard(
                                      itemTitle: itemDetails['title'] ??
                                          'Unknown Item',
                                      reportReason: report['reportReason'] ??
                                          'No reason provided',
                                      reporterName:
                                          report['reporterName'] ?? 'Unknown',
                                      photoUrl: itemDetails['photo'] ?? '',
                                      complaintDetails: complaintDetails,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                AdminDetailedItemScreen(
                                                    itemId:
                                                        itemDetails['itemId']),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
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
        ));
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                strokeWidth: 2,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  height: 16,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: errorColor, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required String itemTitle,
    required String reportReason,
    required String reporterName,
    required String photoUrl,
    required String complaintDetails,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photoUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade200,
                    child: Icon(Icons.image_not_supported,
                        size: 32, color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemTitle,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    SizedBox(height: 4),
                    if (complaintDetails.isNotEmpty)
                      Text(
                        complaintDetails,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: textMedium,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "View Details",
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryYellow,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: primaryYellow,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
