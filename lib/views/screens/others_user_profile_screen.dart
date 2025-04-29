import 'package:bees/controllers/blocked_user_controller.dart';
import 'package:bees/controllers/reported_user_controller.dart';
import 'package:bees/models/blocked_user_model.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/reported_user_model.dart';
import 'package:bees/models/user_model.dart';
import 'package:bees/views/screens/detailed_item_screen.dart';
import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/message_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OthersUserProfileScreen extends StatefulWidget {
  final String userId;

  const OthersUserProfileScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  _OthersUserProfileScreenState createState() =>
      _OthersUserProfileScreenState();
}

class _OthersUserProfileScreenState extends State<OthersUserProfileScreen>
    with SingleTickerProviderStateMixin {
  late Future<User> userProfileData;
  late Future<List<Item>> activeItems;
  final ReportedUserController _reportedUserController =
      ReportedUserController();
  final BlockedUserController _blockedUserController = BlockedUserController();
  String currentUserId = '';
  bool isBlocked = false;
  late TabController _tabController;
  int _selectedIndex = 0; // Default to the first tab

  // Modern trading app color palette
  final Color primaryColor = Color(0xFFFFC857);
  final Color secondaryColor = Color(0xFF6C5CE7);
  final Color accentColor = Color(0xFF00D2D3);
  final Color backgroundColor = Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;
  final Color textDark = Color(0xFF1A1D1F);
  final Color textMedium = Color(0xFF6F767E);
  final Color textLight = Color(0xFFB1B5C3);
  final Color errorColor = Color(0xFFFF5252);
  final Color successColor = Color(0xFF00C48C);
  final Color borderColor = Color(0xFFEBEEF2);

  @override
  void initState() {
    super.initState();
    userProfileData = fetchUserProfile();
    activeItems = fetchActiveItems();
    _getCurrentUserId();
    checkIfBlocked();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        currentUserId = currentUser.uid;
      });
    }
  }

  void checkIfBlocked() async {
    bool blocked = await _blockedUserController.isUserBlocked(widget.userId);
    setState(() {
      isBlocked = blocked;
    });
  }

  void toggleBlock() async {
    if (isBlocked) {
      await _blockedUserController.unblockUser(currentUserId, widget.userId);
    } else {
      await _blockedUserController.blockUser(currentUserId, widget.userId);
    }

    setState(() {
      isBlocked = !isBlocked;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isBlocked ? Icons.block : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              isBlocked
                  ? 'User blocked successfully'
                  : 'User unblocked successfully',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: isBlocked ? errorColor : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  Future<User> fetchUserProfile() async {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    if (!doc.exists) {
      throw Exception("User not found");
    }
    return User.fromMap(doc.data()!);
  }

  Future<List<Item>> fetchActiveItems() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('itemOwnerId', isEqualTo: widget.userId)
        .where('itemStatus', isEqualTo: 'active')
        .get();
    return querySnapshot.docs
        .map((doc) => Item.fromJson(doc.data(), doc.id))
        .toList();
  }

  Future<Map<String, dynamic>> fetchUserStats() async {
    // Get active items count
    var activeItemsQuery = await FirebaseFirestore.instance
        .collection('items')
        .where('itemOwnerId', isEqualTo: widget.userId)
        .where('itemStatus', isEqualTo: 'active')
        .get();

    // Get completed transactions count
    var completedItemsQuery = await FirebaseFirestore.instance
        .collection('items')
        .where('itemOwnerId', isEqualTo: widget.userId)
        .where('itemStatus', isEqualTo: 'beesed')
        .get();

    // Get join date
    var userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();

    DateTime joinDate = DateTime.now();
    if (userDoc.exists && userDoc.data()!.containsKey('createdAt')) {
      joinDate = (userDoc.data()!['createdAt'] as Timestamp).toDate();
    }

    return {
      'activeItems': activeItemsQuery.docs.length,
      'completedItems': completedItemsQuery.docs.length,
      'joinDate': joinDate,
    };
  }

  void _showReportDialog() {
    String? selectedReason;
    String details = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(24),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.report_problem_outlined, color: errorColor),
                        SizedBox(width: 12),
                        Text(
                          "Report User",
                          style: GoogleFonts.nunito(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      "Please select a reason:",
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildReportOption("Harassment", selectedReason,
                                (value) {
                              setDialogState(() => selectedReason = value);
                            }),
                            _buildReportOption(
                                "Suspicious or Fraudulent Behavior",
                                selectedReason, (value) {
                              setDialogState(() => selectedReason = value);
                            }),
                            _buildReportOption(
                                "Inappropriate Profile Content", selectedReason,
                                (value) {
                              setDialogState(() => selectedReason = value);
                            }),
                            _buildReportOption(
                                "Hate Speech or Bullying", selectedReason,
                                (value) {
                              setDialogState(() => selectedReason = value);
                            }),
                            _buildReportOption(
                                "Violent Behavior", selectedReason, (value) {
                              setDialogState(() => selectedReason = value);
                            }),
                            _buildReportOption("Other", selectedReason,
                                (value) {
                              setDialogState(() => selectedReason = value);
                            }),
                            if (selectedReason == 'Other')
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: "Please describe your complaint",
                                    hintStyle:
                                        GoogleFonts.nunito(color: textLight),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide:
                                          BorderSide(color: borderColor),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                          color: primaryColor, width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 16),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  style: GoogleFonts.nunito(color: textDark),
                                  maxLines: 3,
                                  onChanged: (text) {
                                    details = text;
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.nunito(
                              color: textMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (selectedReason == null ||
                                (selectedReason == 'Other' &&
                                    details.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please select a reason and provide details if necessary',
                                    style: GoogleFonts.nunito(),
                                  ),
                                  backgroundColor: errorColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            var report = ReportedUser(
                              reportReason: selectedReason!,
                              complaintDetails:
                                  selectedReason == 'Other' ? details : '',
                              reportedBy: currentUserId,
                              complaintID:
                                  DateTime.now().millisecondsSinceEpoch,
                              userId: widget.userId,
                            );

                            try {
                              await _reportedUserController.addReport(report);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline,
                                          color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Report submitted successfully',
                                        style: GoogleFonts.nunito(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: successColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  margin: EdgeInsets.all(16),
                                ),
                              );
                              Navigator.of(context).pop();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to report user: $e',
                                    style: GoogleFonts.nunito(),
                                  ),
                                  backgroundColor: errorColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: errorColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                          child: Text(
                            "Submit Report",
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildReportOption(
      String title, String? selectedReason, Function(String?) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selectedReason == title
            ? errorColor.withOpacity(0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedReason == title ? errorColor : borderColor,
          width: 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: GoogleFonts.nunito(
            color: selectedReason == title ? errorColor : textDark,
            fontWeight:
                selectedReason == title ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        value: title,
        groupValue: selectedReason,
        onChanged: onChanged as void Function(String?),
        activeColor: errorColor,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<User>(
        future: userProfileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: textLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: textMedium,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.arrow_back, size: 18),
                    label: Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: Text(
                'No data available',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  color: textMedium,
                ),
              ),
            );
          }

          User user = snapshot.data!;
          String userName = '${user.firstName} ${user.lastName}';
          String userEmail = user.emailAddress;
          String userProfilePicture = user.profilePicture;
          double userRating = user.userRating;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  backgroundColor: Colors.white,
                  floating: false,
                  pinned: true,
                  elevation: 0,
                  leading: Container(
                    margin: EdgeInsets.all(8),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: textDark),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  actions: [
                    Container(
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isBlocked ? Icons.lock_open : Icons.block,
                          color: isBlocked ? primaryColor : errorColor,
                        ),
                        onPressed: toggleBlock,
                        tooltip: isBlocked ? "Unblock User" : "Block User",
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.flag_outlined, color: errorColor),
                        onPressed: _showReportDialog,
                        tooltip: "Report User",
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: _buildProfileHeader(user),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      indicatorColor: primaryColor,
                      indicatorWeight: 3,
                      labelColor: textDark,
                      unselectedLabelColor: textMedium,
                      labelStyle: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: [
                        Tab(text: "Listings"),
                        Tab(text: "About"),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                // Listings Tab
                _buildListingsTab(),

                // About Tab
                _buildAboutTab(user),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
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
          selectedItemColor: primaryColor,
          unselectedItemColor: textMedium,
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
              icon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile picture
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: user.profilePicture.isNotEmpty
                    ? Image.network(
                        user.profilePicture,
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primaryColor),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[200],
                            child: Icon(Icons.person,
                                color: Colors.grey, size: 60),
                          );
                        },
                      )
                    : Container(
                        width: 120,
                        height: 120,
                        color: Colors.grey[200],
                        child: Icon(Icons.person, color: Colors.grey, size: 60),
                      ),
              ),
            ),
          ),
          SizedBox(height: 16),

          // User name and verification badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${user.firstName} ${user.lastName}",
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.verified,
                color: primaryColor,
                size: 20,
              ),
            ],
          ),
          SizedBox(height: 8),

          // User rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (index) {
                return Icon(
                  index < user.userRating.floor()
                      ? Icons.star
                      : (index < user.userRating
                          ? Icons.star_half
                          : Icons.star_border),
                  color: primaryColor,
                  size: 20,
                );
              }),
              SizedBox(width: 8),
              Text(
                user.userRating.toStringAsFixed(1),
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // User stats
          FutureBuilder<Map<String, dynamic>>(
            future: fetchUserStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return SizedBox.shrink();
              }

              var stats = snapshot.data!;

              return Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem(
                        "${stats['activeItems']}",
                        "Active",
                        Icons.inventory_2_outlined,
                      ),
                      _buildDivider(),
                      _buildStatItem(
                        "${stats['completedItems']}",
                        "Beesed",
                        Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: primaryColor,
          size: 24,
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            color: textMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: borderColor,
    );
  }

  Widget _buildListingsTab() {
    return FutureBuilder<List<Item>>(
      future: activeItems,
      builder: (context, itemsSnapshot) {
        if (itemsSnapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          );
        }

        if (itemsSnapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: textLight,
                ),
                SizedBox(height: 16),
                Text(
                  'Error loading items',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please try again later',
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          );
        }

        if (!itemsSnapshot.hasData || itemsSnapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: textLight,
                ),
                SizedBox(height: 16),
                Text(
                  'No active listings',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This user has no items for sale',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: textMedium,
                  ),
                ),
              ],
            ),
          );
        }

        var items = itemsSnapshot.data!;
        return GridView.builder(
          padding: EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            var item = items[index];
            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(Item item) {
    bool hidePrice = item.category.toLowerCase() == 'donate' ||
        item.category.toLowerCase() == 'exchange';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailedItemScreen(itemId: item.itemId!),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  // Image
                  AspectRatio(
                    aspectRatio: 1,
                    child: item.photoUrl != null
                        ? Image.network(
                            item.photoUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryColor),
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(Icons.image_not_supported,
                                    color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(Icons.image_not_supported,
                                color: Colors.grey),
                          ),
                  ),

                  // Category badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.category,
                        style: GoogleFonts.nunito(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Item details
            Padding(
              padding: EdgeInsets.all(1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1),
                  if (!hidePrice)
                    Text(
                      '₺${item.price.toStringAsFixed(2)}',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    )
                  else
                    Text(
                      item.category,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                        color: secondaryColor,
                      ),
                    ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      SizedBox(width: 4),
                      Text(
                        item.condition,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: textMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(User user) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Join date card
          Container(
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
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: primaryColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Member Since",
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: textMedium,
                      ),
                    ),
                    SizedBox(height: 4),
                    FutureBuilder<Map<String, dynamic>>(
                      future: fetchUserStats(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Text(
                            "Loading...",
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          );
                        }

                        DateTime joinDate = snapshot.data!['joinDate'];
                        return Text(
                          DateFormat('MMMM yyyy').format(joinDate),
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Email card
          Container(
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
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: secondaryColor,
                    size: 14,
                  ),
                ),
                SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Email",
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: textMedium,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user.emailAddress,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => RequestsScreen()),
        );
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
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
