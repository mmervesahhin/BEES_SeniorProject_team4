import 'package:bees/controllers/blocked_user_controller.dart';
import 'package:bees/controllers/reported_user_controller.dart';
import 'package:bees/models/blocked_user_model.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/reported_user_model.dart';
import 'package:bees/models/user_model.dart';
import 'package:bees/views/screens/detailed_item_screen.dart';
import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class OthersUserProfileScreen extends StatefulWidget {
  final String userId;

  const OthersUserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _OthersUserProfileScreenState createState() => _OthersUserProfileScreenState();
}

class _OthersUserProfileScreenState extends State<OthersUserProfileScreen> {
  late Future<User> userProfileData;
  late Future<List<Item>> activeItems;
  final ReportedUserController _reportedUserController = ReportedUserController();
  final BlockedUserController _blockedUserController = BlockedUserController();
  String currentUserId = '';
  bool isBlocked = false;
  
  // Color scheme
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);

  @override
  void initState() {
    super.initState();
    userProfileData = fetchUserProfile();
    activeItems = fetchActiveItems();
    _getCurrentUserId();
    checkIfBlocked();
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
        content: Text(
          isBlocked
              ? 'User blocked successfully'
              : 'User unblocked successfully',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isBlocked ? Colors.red : primaryYellow,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<User> fetchUserProfile() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
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
    return querySnapshot.docs.map((doc) => Item.fromJson(doc.data(), doc.id)).toList();
  }

  void _showReportDialog() {
    String? selectedReason;
    String details = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                "Report User",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Please select a reason:",
                      style: GoogleFonts.nunito(color: textDark),
                    ),
                    SizedBox(height: 8),
                    _buildReportOption("Harassment", selectedReason, (value) {
                      setDialogState(() => selectedReason = value);
                    }),
                    _buildReportOption("Suspicious or Fraudulent Behavior", selectedReason, (value) {
                      setDialogState(() => selectedReason = value);
                    }),
                    _buildReportOption("Inappropriate Profile Content", selectedReason, (value) {
                      setDialogState(() => selectedReason = value);
                    }),
                    _buildReportOption("Hate Speech or Bullying", selectedReason, (value) {
                      setDialogState(() => selectedReason = value);
                    }),
                    _buildReportOption("Violent Behavior", selectedReason, (value) {
                      setDialogState(() => selectedReason = value);
                    }),
                    _buildReportOption("Other", selectedReason, (value) {
                      setDialogState(() => selectedReason = value);
                    }),
                    if (selectedReason == 'Other')
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Please describe your complaint",
                            hintStyle: GoogleFonts.nunito(color: textLight),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: primaryYellow),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            filled: true,
                            fillColor: backgroundColor,
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.nunito(
                      color: textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedReason == null || (selectedReason == 'Other' && details.isEmpty)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select a reason and provide details if necessary',
                            style: GoogleFonts.nunito(),
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    var report = ReportedUser(
                      reportReason: selectedReason!,
                      complaintDetails: selectedReason == 'Other' ? details : '',
                      reportedBy: currentUserId,
                      complaintID: DateTime.now().millisecondsSinceEpoch,
                      userId: widget.userId,
                    );

                    try {
                      await _reportedUserController.addReport(report);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Report submitted successfully',
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: primaryYellow,
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
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Submit",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
            );
          },
        );
      },
    );
  }

  Widget _buildReportOption(String title, String? selectedReason, Function(String?) onChanged) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: selectedReason == title ? lightYellow : backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedReason == title ? primaryYellow : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: GoogleFonts.nunito(
            color: textDark,
            fontWeight: selectedReason == title ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        value: title,
        groupValue: selectedReason,
        onChanged: onChanged as void Function(String?),
        activeColor: primaryYellow,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
      appBar: AppBar(
        title: Text(
          'User Profile',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textDark),
      ),
      body: FutureBuilder<User>(
        future: userProfileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
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
                      color: textLight,
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
                  color: textLight,
                ),
              ),
            );
          }

          User user = snapshot.data!;
          String userName = '${user.firstName} ${user.lastName}';
          String userEmail = user.emailAddress;
          String userProfilePicture = user.profilePicture;
          double userRating = user.userRating;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: lightYellow,
                      backgroundImage: userProfilePicture.isNotEmpty
                          ? NetworkImage(userProfilePicture)
                          : null,
                      child: userProfilePicture.isEmpty
                          ? Icon(Icons.person, size: 50, color: primaryYellow)
                          : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      userName,
                      style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: textLight,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star,
                          color: primaryYellow,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          userRating.toStringAsFixed(1),
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showReportDialog,
                            icon: Icon(Icons.flag, color: Colors.red),
                            label: Text(
                              "Report",
                              style: GoogleFonts.nunito(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.withOpacity(0.5)),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: toggleBlock,
                            icon: Icon(
                              isBlocked ? Icons.lock_open : Icons.block,
                              color: isBlocked ? primaryYellow : Colors.red,
                            ),
                            label: Text(
                              isBlocked ? "Unblock" : "Block",
                              style: GoogleFonts.nunito(
                                color: isBlocked ? primaryYellow : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isBlocked
                                    ? primaryYellow.withOpacity(0.5)
                                    : Colors.red.withOpacity(0.5),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Active Items Section
              Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  "Active Items",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
              ),
              
              // Active Items List
              Expanded(
                child: FutureBuilder<List<Item>>(
                  future: activeItems,
                  builder: (context, itemsSnapshot) {
                    if (itemsSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryYellow),
                        ),
                      );
                    }

                    if (itemsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading items',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: textLight,
                          ),
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
                              'No active items',
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
                                color: textLight,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    var items = itemsSnapshot.data!;
                    return ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        var item = items[index];
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
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item Image
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  child: Image.network(
                                    item.photoUrl ?? 'https://via.placeholder.com/100',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                
                                // Item Details
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: textDark,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        if (!hidePrice) ...[
                                          Row(
                                            children: [
                                              Text(
                                                '₺${item.price.toDouble()}',
                                                style: GoogleFonts.nunito(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: primaryYellow,
                                                ),
                                              ),
                                              if (item.paymentPlan != null && item.paymentPlan!.isNotEmpty)
                                                Text(
                                                  ' ${item.paymentPlan}',
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 12,
                                                    color: textLight,
                                                  ),
                                                ),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                        ],
                                        
                                        // Tags
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _buildItemTag(item.category, primaryYellow),
                                            _buildItemTag(item.condition, lightYellow),
                                            if (item.departments is List && (item.departments as List).isNotEmpty)
                                              _buildItemTag(
                                                (item.departments as List).length > 1
                                                    ? '${(item.departments as List)[0]} +${(item.departments as List).length - 1}'
                                                    : (item.departments as List)[0],
                                                backgroundColor,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
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

  Widget _buildItemTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
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
