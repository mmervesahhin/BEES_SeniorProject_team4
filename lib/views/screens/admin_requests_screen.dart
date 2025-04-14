import 'package:bees/controllers/admin_controller.dart';
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_others_user_profile_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/controllers/request_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:bees/models/user_model.dart' as bees;

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  _AdminRequestsScreenState createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  TextEditingController _searchController = TextEditingController();
  final RequestController _requestController = RequestController();
  final currentUser = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';
  final AdminController _controller = AdminController();
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();
  
  // Color scheme
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AdminHomeScreen()),
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AdminRequestsScreen()),
        );
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => AdminReportsScreen()),
        );
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
  }

  void _navigateToProfile(String userId) {
    if (userId == currentUser?.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminOthersUserProfileScreen(userId: userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(
              Icons.assignment_rounded,
              color: primaryYellow,
              size: 28,
            ),
            const SizedBox(width: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'BEES ',
                    style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryYellow,
                    ),
                  ),
                  TextSpan(
                    text: 'admin',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryYellow,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isSearchFocused ? Colors.white : backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSearchFocused ? primaryYellow : Colors.grey[300]!,
                  width: 1.5,
                ),
                boxShadow: _isSearchFocused
                    ? [
                        BoxShadow(
                          color: primaryYellow.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: "Search requests...",
                  hintStyle: GoogleFonts.nunito(
                    color: textLight,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: _isSearchFocused ? primaryYellow : textLight,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: textLight,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: textDark,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: _buildRequestList(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryYellow,
          unselectedItemColor: textLight,
          selectedLabelStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.nunito(
            fontSize: 12,
          ),
          currentIndex: _selectedIndex,
          elevation: 0,
          onTap: _onItemTapped,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: FaIcon(FontAwesomeIcons.shop, size: 20),
              label: 'Items',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded, size: 24),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_rounded, size: 22),
              label: 'Complaints',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded, size: 24),
              label: 'Analysis',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded, size: 24),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList() {
    return StreamBuilder<List<Request>>(
      stream: _requestController.getRequests(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: primaryYellow,
              strokeWidth: 3,
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_late_rounded,
                  size: 64,
                  color: textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  "No requests found",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    "Try a different search term",
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: textLight,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        String searchQueryLower = _searchQuery.toLowerCase();

        List<Request> filteredRequests = snapshot.data!.where((req) {
          String contentLower = req.requestContent.toLowerCase();
          
          bees.User? user = _requestController.cachedUsers[req.requestOwnerID];
          String userNameLower = user != null ? "${user.firstName} ${user.lastName}".toLowerCase() : "";

          return contentLower.contains(searchQueryLower) || userNameLower.contains(searchQueryLower); 
        }).toList();

        filteredRequests.sort((a, b) {
          int relevanceA = _calculateRelevance(a.requestContent, searchQueryLower);
          int relevanceB = _calculateRelevance(b.requestContent, searchQueryLower);
          return relevanceB.compareTo(relevanceA);
        });

        if (filteredRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 64,
                  color: textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  "No matching requests",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try a different search term",
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: textLight,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: filteredRequests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(filteredRequests[index]);
          },
        );
      },
    );
  }

  int _calculateRelevance(String text, String query) {
    if (query.isEmpty) return 1;
    text = text.toLowerCase();
    if (text.startsWith(query)) return 3;
    if (text.contains(query)) return 2;
    return 1;
  }

  Widget _buildRequestCard(Request request) {
    return FutureBuilder<bees.User?>(
      future: _requestController.getUserByRequestID(request.requestID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _loadingRequestCard(request); 
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return _errorRequestCard(request); 
        }

        bees.User user = snapshot.data!;

        return Card(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.5,
          color:backgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToProfile(user.userID),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: primaryYellow.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: lightYellow.withOpacity(0.3),
                          backgroundImage: user.profilePicture.isNotEmpty
                              ? NetworkImage(user.profilePicture)
                              : null,
                          child: user.profilePicture.isEmpty
                              ? Icon(Icons.person, color: primaryYellow, size: 24)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToProfile(user.userID),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${user.firstName} ${user.lastName}",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: textDark,
                              ),
                            ),
                            Text(
                              _formatDate(request.creationDate),
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: textLight,
                        size: 22,
                      ),
                      onPressed: () {
                        _controller.showRequestRemoveOptions(context, request);
                      },
                      tooltip: 'More options',
                      splashRadius: 24,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    
                  ),
                  child: Text(
                    request.requestContent,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      height: 1.4,
                      color: textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
    
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _loadingRequestCard(Request request) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: lightYellow.withOpacity(0.3),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: primaryYellow,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "Loading user...",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w500,
                color: textLight,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _errorRequestCard(Request request) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red[50],
              child: Icon(Icons.error_outline, color: Colors.red[700], size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              "User not found",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w500,
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return "Today at ${DateFormat('h:mm a').format(date)}";
    } else if (difference.inDays == 1) {
      return "Yesterday at ${DateFormat('h:mm a').format(date)}";
    } else if (difference.inDays < 7) {
      return "${DateFormat('EEEE').format(date)} at ${DateFormat('h:mm a').format(date)}";
    } else {
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    }
  }
}
