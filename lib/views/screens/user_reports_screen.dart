import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/views/screens/admin_others_user_profile_screen.dart';
import 'package:bees/controllers/admin_controller.dart';
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  _UserReportsScreenState createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  int _selectedIndex = 2;
  final AdminController _adminController = AdminController();
  final currentUser = FirebaseAuth.instance.currentUser;

  // Declare variables to hold the selected reason and ban duration
  String? _selectedBanReason;
  String? _selectedBanDuration;
  String _banExplanation = '';
  
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

  void _navigateToProfile(String userId) {
    if (userId == currentUser?.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminOthersUserProfileScreen(userId: userId),
        ),
      );
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
        title: Text(
          'User Complaints',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Reported Users",
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Review and manage reported users",
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: textMedium,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: StreamBuilder(
                  stream: _adminController.getReportedUsers(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
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
                              "No reported users",
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textMedium,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "There are no reported users at this time",
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: textMedium,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView(
                      children: snapshot.data!.docs.map((doc) {
                        return FutureBuilder(
                          future: Future.wait([
                            _adminController.getUserInfo(doc['reportedBy']), 
                            _adminController.getUserInfo(doc['userId'])
                          ]),
                          builder: (context, AsyncSnapshot<List<Map<String, dynamic>?>> userSnapshots) {
                            if (userSnapshots.connectionState == ConnectionState.waiting) {
                              return _buildLoadingCard();
                            }
                            
                            String reportedByName = '${userSnapshots.data?[0]?['firstName'] ?? 'Unknown Reporter'} ${userSnapshots.data?[0]?['lastName'] ?? ''}';
                            String reportedUserName = '${userSnapshots.data?[1]?['firstName'] ?? 'Unknown User'} ${userSnapshots.data?[1]?['lastName'] ?? ''}';
                            String? profileImageUrl = userSnapshots.data?[1]?['profilePicture'];
                            String? complaintDetails = doc['complaintDetails'];
                            String reportReason = doc['reportReason'] ?? 'No reason provided';

                            return _buildReportedUserCard(
                              userId: doc['userId'],
                              userName: reportedUserName,
                              reporterName: reportedByName,
                              profileImageUrl: profileImageUrl,
                              reportReason: reportReason,
                              complaintDetails: complaintDetails,
                              complaintId: doc['complaintID'].toString(), // Convert to String
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              SizedBox(height: 24),
              Text(
                "Banned Users",
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Manage currently banned users",
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: textMedium,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: StreamBuilder(
                  stream: _adminController.getBannedUsers(),
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
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
                              "No banned users",
                              style: GoogleFonts.nunito(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textMedium,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "There are no banned users at this time",
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: textMedium,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView(
                      children: snapshot.data!.docs.map((doc) {
                        return FutureBuilder(
                          future: _adminController.getUserInfo(doc.id),
                          builder: (context, AsyncSnapshot<Map<String, dynamic>?> userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return _buildLoadingCard();
                            }
                            
                            String userName = '${userSnapshot.data?['firstName'] ?? 'Unknown User'} ${userSnapshot.data?['lastName'] ?? ''}';
                            String? profileImageUrl = userSnapshot.data?['profilePicture'];
                            String banExpiration = (userSnapshot.data?['banEndDate'] as Timestamp?)?.toDate().toString().substring(0, 16) ?? 'Permanent';

                            return _buildBannedUserCard(
                              userId: doc.id,
                              userName: userName,
                              profileImageUrl: profileImageUrl,
                              banExpiration: banExpiration,
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
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
          elevation: 0,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
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
        ),
      ),
    );
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportedUserCard({
  required String userId,
  required String userName,
  required String reporterName,
  String? profileImageUrl,
  required String reportReason,
  String? complaintDetails,
  required dynamic complaintId, // Change to dynamic type
}){
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
                  onTap: () => _navigateToProfile(userId),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: profileImageUrl != null
                        ? NetworkImage(profileImageUrl)
                        : null,
                    child: profileImageUrl == null
                        ? Icon(Icons.person, color: Colors.grey.shade400)
                        : null,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToProfile(userId),
                    child: Text(
                      userName,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: errorColor.withOpacity(0.2), width: 1),
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
            SizedBox(height: 8),
            if (complaintDetails != null && complaintDetails.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  complaintDetails,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: textMedium,
                  ),
                ),
              ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showBanDialog(userId),
                  icon: Icon(Icons.block, size: 18, color: errorColor),
                  label: Text(
                    "Ban User",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: errorColor,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                onPressed: () => _adminController.ignoreUserReport(complaintId.toString()),
                icon: Icon(Icons.delete_outline, size: 18, color: primaryYellow),
                label: Text(
                  "Dismiss",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryYellow,
                  ),
                ),
              ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannedUserCard({
    required String userId,
    required String userName,
    String? profileImageUrl,
    required String banExpiration,
  }) {
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
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _navigateToProfile(userId),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: profileImageUrl != null
                    ? NetworkImage(profileImageUrl)
                    : null,
                child: profileImageUrl == null
                    ? Icon(Icons.person, color: Colors.grey.shade400)
                    : null,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _navigateToProfile(userId),
                    child: Text(
                      userName,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: textMedium),
                      SizedBox(width: 4),
                      Text(
                        "Ban expires: $banExpiration",
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: textMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _showUnbanDialog(userId),
              icon: Icon(Icons.check_circle_outline, size: 18, color: successColor),
              label: Text(
                "Unban",
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: successColor,
                ),
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

  void _showUnbanDialog(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Unban User',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          content: Text(
            'Are you sure you want to unban this user?',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: textMedium,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: textMedium,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                _adminController.unbanUser(userId);
                Navigator.of(context).pop();
              },
              child: Text(
                'Unban',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBanDialog(String userId) {
    setState(() {
      _selectedBanReason = null;
      _selectedBanDuration = null;
      _banExplanation = '';
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Ban User',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Ban Reason',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textMedium,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedBanReason,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBanReason = newValue;
                          });
                        },
                        hint: Text(
                          'Select Ban Reason',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: textMedium,
                          ),
                        ),
                        isExpanded: true,
                        underline: SizedBox(),
                        items: <String>[
                          'Harassment',
                          'Suspicious or Fraudulent Behavior',
                          'Inappropriate Profile Picture',
                          'Name or Surname Issues',
                          'Hate Speech or Bullying',
                          'Violent Behavior',
                          'Other'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: textDark,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_selectedBanReason == 'Other') ...[
                      SizedBox(height: 16),
                      Text(
                        'Explanation',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textMedium,
                        ),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _banExplanation = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter explanation',
                          hintStyle: GoogleFonts.nunito(
                            fontSize: 14,
                            color: textLight,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: textDark,
                        ),
                        maxLines: 3,
                      ),
                    ],
                    SizedBox(height: 16),
                    Text(
                      'Select Ban Duration',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textMedium,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedBanDuration,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBanDuration = newValue;
                          });
                        },
                        hint: Text(
                          'Select Ban Duration',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            color: textMedium,
                          ),
                        ),
                        isExpanded: true,
                        underline: SizedBox(),
                        items: <String>[
                          'Permanent',
                          '7 days',
                          '10 days',
                          '15 days',
                          '30 days'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: textDark,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: textMedium,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: (_selectedBanReason == null ||
                          _selectedBanDuration == null ||
                          (_selectedBanReason == 'Other' && _banExplanation.isEmpty))
                      ? null
                      : () {
                          _adminController.banUser(
                            userId: userId,
                            banReason: _selectedBanReason!,
                            explanation: _banExplanation,
                            banPeriod: _selectedBanDuration!,
                          );
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    'Ban User',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}