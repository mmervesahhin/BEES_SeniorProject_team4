import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/views/screens/create_request_screen.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/controllers/request_controller.dart';
import 'package:bees/views/screens/message_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_list_screen.dart';
import 'package:bees/views/screens/others_user_profile_screen.dart';
import 'package:bees/controllers/reported_request_controller.dart';
import 'package:bees/models/reported_request_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:bees/models/user_model.dart' as bees;

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  _RequestsScreenState createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 1;
  TextEditingController _searchController = TextEditingController();
  final RequestController _requestController = RequestController();
  String _searchQuery = '';
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
  late AnimationController _animationController;
  bool _isSearchFocused = false;
  final FocusNode _searchFocusNode = FocusNode();

  // App colors
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => FavoritesScreen()),
        );
        break;
      case 3:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => UserProfileScreen()),
        );
        break;
    }
  }

  void _navigateToCreateRequest() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateRequestScreen()),
    );
  }

  void _navigateToProfile(String userId, BuildContext context) {
    if (userId == FirebaseAuth.instance.currentUser!.uid) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserProfileScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OthersUserProfileScreen(userId: userId)),
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
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            
            const SizedBox(width: 10),
            Text(
              'Requests',
              style: GoogleFonts.nunito(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.message_rounded, size: 24),
            
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageListScreen(),
                ),
              );
            },
            color: textDark,
          ),
          const SizedBox(width: 8),
        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateRequest,
        backgroundColor: primaryYellow,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
              icon: FaIcon(FontAwesomeIcons.shop, size: 22),
              label: 'Items',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_rounded, size: 22),
              label: 'Requests',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_rounded, size: 22),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_rounded, size: 22),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList() {
    return StreamBuilder<List<Request>>(
      stream: _requestController.getRequests(currentUserId),
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
          padding: const EdgeInsets.only(bottom: 80),
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
                      onTap: () {
                        _navigateToProfile(user.userID, context);
                      },
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
                        onTap: () {
                          _navigateToProfile(user.userID, context);
                        },
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
                    if (request.requestOwnerID != currentUserId) ...[
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.message_outlined,
                            color: primaryYellow,
                            size: 22,
                          ),
                          onPressed: () {
                            _navigateToMessageScreen(request, "Request");
                          },
                          tooltip: 'Message',
                          splashRadius: 24,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: textLight,
                            size: 22,
                          ),
                          onPressed: () {
                            _showReportOptions(context, request);
                          },
                          tooltip: 'More options',
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ],
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    
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
          
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReportOptions(BuildContext context, Request request) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  "Report Request",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightYellow.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.report_outlined, color: primaryYellow, size: 20),
                  ),
                  title: Text(
                    "Inappropriate for BEES",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textDark,
                    ),
                  ),
                  onTap: () {
                    _reportRequest(request, "Inappropriate for BEES");
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: lightYellow.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.gavel_rounded, color: primaryYellow, size: 20),
                  ),
                  title: Text(
                    "Illegal request",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textDark,
                    ),
                  ),
                  onTap: () {
                    _reportRequest(request, "Illegal request");
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _reportRequest(Request request, String reason) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print("Error: User not logged in");
      return;
    }

    bool alreadyReported = await ReportedRequestController().hasUserReportedRequest(request.requestID, userId);
    
    if (alreadyReported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You have already reported this request.",
            style: GoogleFonts.nunito(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.grey[800],
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    ReportedRequest reportedRequest = ReportedRequest(
      requestId: request.requestID,
      reportedBy: userId,
      reportReason: reason,
      reportDate: DateTime.now(),
    );

    await ReportedRequestController().reportRequest(reportedRequest);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Text(
              "Request reported successfully!",
              style: GoogleFonts.nunito(),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: primaryYellow,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _navigateToMessageScreen(dynamic entity, String entityType) {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("User is not logged in");
      return;
    }
    String senderId = "";
    String receiverId = currentUser.uid;

    if (entityType == "Item") {
      senderId = entity.itemOwnerId;
    } else if (entityType == "Request") {
      senderId = entity.requestOwnerID;
    }
    
    if (senderId == receiverId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You cannot send a message to yourself!",
            style: GoogleFonts.nunito(),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          backgroundColor: Colors.grey[800],
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MessageScreen(
          entity: entity,
          entityType: entityType,
          senderId: senderId,
          receiverId: receiverId,
        ),
      ),
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
