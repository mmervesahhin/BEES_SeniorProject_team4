import 'package:bees/controllers/admin_controller.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/user_model.dart';
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_detailed_item_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

// Define theme colors to match AdminDetailedItemScreen
class AppColors {
  static const Color primaryYellow = Color(0xFFFFC857);
  static const Color lightYellow = Color(0xFFFFE3A9);
  static const Color backgroundColor = Color(0xFFF8F8F8);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF8A8A8A);
  static const Color errorColor = Color(0xFFFF5252);
  static const Color successColor = Color(0xFF00C48C);

  // Define text styles with Nunito font
  static TextStyle get headingStyle => GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textDark,
      );

  static TextStyle get subheadingStyle => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textDark,
      );

  static TextStyle get bodyStyle => GoogleFonts.nunito(
        fontSize: 16,
        color: textDark,
      );

  static TextStyle get smallStyle => GoogleFonts.nunito(
        fontSize: 14,
        color: textLight,
      );

  static TextStyle get chipStyle => GoogleFonts.nunito(
        fontSize: 12,
        color: textDark,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get priceStyle => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryYellow,
      );
}

class AdminOthersUserProfileScreen extends StatefulWidget {
  final String userId;

  const AdminOthersUserProfileScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  _OthersUserProfileScreenState createState() =>
      _OthersUserProfileScreenState();
}

class _OthersUserProfileScreenState
    extends State<AdminOthersUserProfileScreen> {
  late Future<User> userProfileData;
  late Future<List<Item>> activeItems;

  String currentUserId = '';
  final AdminController _adminController = AdminController();
  String? _selectedBanReason;
  String? _selectedBanDuration;
  String _banExplanation = '';

  @override
  void initState() {
    super.initState();
    userProfileData = fetchUserProfile();
    activeItems = fetchActiveItems();
    _getCurrentUserId();
  }

  void _getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        currentUserId = currentUser.uid;
      });
    }
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

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: AppColors.chipStyle,
      ),
    );
  }

  List<Widget> _buildDepartmentsTag(List<dynamic> departments) {
    if (departments.isEmpty) return [];

    List<String> visibleDepartments =
        departments.map((e) => e.toString()).take(1).toList();

    if (departments.length > 1) {
      visibleDepartments.add('...');
    }

    return visibleDepartments
        .map((department) => _buildTag(department, AppColors.primaryYellow))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'User Profile',
          style: GoogleFonts.nunito(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: AppColors.textDark),
        centerTitle: true,
      ),
      body: FutureBuilder<User>(
        future: userProfileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
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
                    color: AppColors.textLight,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Error loading profile',
                    style: AppColors.subheadingStyle,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: AppColors.smallStyle,
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            User user = snapshot.data!;
            String userName = '${user.firstName} ${user.lastName}';
            String userEmail = user.emailAddress;
            String userProfilePicture = user.profilePicture;
            double userRatingDouble = user.userRating;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Profile Header
                    Stack(
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.lightYellow,
                                AppColors.primaryYellow,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 30,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              // Profile Picture
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: userProfilePicture.isNotEmpty
                                      ? Image.network(
                                          userProfilePicture,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: Colors.white,
                                          child: Icon(
                                            Icons.person,
                                            size: 50,
                                            color: AppColors.primaryYellow,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(height: 12),

                              // User Name
                              Text(
                                userName,
                                style: GoogleFonts.nunito(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 4),

                              // User Email
                              Text(
                                userEmail,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: AppColors.textDark.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // User Stats
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "User Information",
                            style: AppColors.subheadingStyle,
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                icon: Icons.star,
                                value: userRatingDouble.toStringAsFixed(1),
                                label: "Rating",
                              ),
                              _buildStatItem(
                                icon: Icons.shopping_bag,
                                value: "Active",
                                label: "Status",
                                valueColor: AppColors.successColor,
                              ),
                              StreamBuilder<QuerySnapshot>(
                                stream: _adminController.getBannedUsers(),
                                builder: (context, banSnapshot) {
                                  bool isBanned = false;
                                  if (banSnapshot.hasData) {
                                    isBanned =
                                        banSnapshot.data!.docs.any((doc) {
                                      return doc['userID'] == user.userID;
                                    });
                                  }
                                  return _buildStatItem(
                                    icon: isBanned
                                        ? Icons.block
                                        : Icons.verified_user,
                                    value: isBanned ? "Banned" : "Active",
                                    label: "Account",
                                    valueColor: isBanned
                                        ? AppColors.errorColor
                                        : AppColors.successColor,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Admin Actions
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Admin Actions",
                            style: AppColors.subheadingStyle,
                          ),
                          SizedBox(height: 16),
                          StreamBuilder<QuerySnapshot>(
                            stream: _adminController.getBannedUsers(),
                            builder: (context, banSnapshot) {
                              bool isBanned = false;
                              if (banSnapshot.hasData) {
                                isBanned = banSnapshot.data!.docs.any((doc) {
                                  return doc['userID'] == user.userID;
                                });
                              }

                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    if (isBanned) {
                                      _showUnbanDialog(user.userID);
                                    } else {
                                      _showBanDialog(user.userID);
                                    }
                                  },
                                  icon: Icon(
                                    isBanned ? Icons.lock_open : Icons.block,
                                    color: AppColors.textDark,
                                    size: 18,
                                  ),
                                  label: Text(
                                    isBanned ? 'Unban User' : 'Ban User',
                                    style: GoogleFonts.nunito(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isBanned
                                        ? AppColors.successColor
                                        : AppColors.errorColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Active Items Section
                    Text(
                      "Active Items",
                      style: AppColors.headingStyle,
                    ),
                    SizedBox(height: 8),
                    Divider(
                      color: Colors.grey.withOpacity(0.3),
                      thickness: 1,
                    ),
                    SizedBox(height: 8),

                    // Active Items List
                    FutureBuilder<List<Item>>(
                      future: activeItems,
                      builder: (context, itemsSnapshot) {
                        if (itemsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryYellow),
                            ),
                          );
                        }

                        if (itemsSnapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading items',
                              style: AppColors.bodyStyle,
                            ),
                          );
                        }

                        if (itemsSnapshot.hasData &&
                            itemsSnapshot.data!.isEmpty) {
                          return Container(
                            padding: EdgeInsets.all(32),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 64,
                                  color: AppColors.textLight,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No active items',
                                  style: AppColors.subheadingStyle,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'This user has no items for sale',
                                  style: AppColors.smallStyle,
                                ),
                              ],
                            ),
                          );
                        }

                        var items = itemsSnapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            var item = items[index];
                            bool hidePrice =
                                item.category.toLowerCase() == 'donate' ||
                                    item.category.toLowerCase() == 'exchange';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        AdminDetailedItemScreen(
                                      itemId: item.itemId!,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Item Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                      child: Image.network(
                                        item.photoUrl ??
                                            'https://via.placeholder.com/400x200',
                                        height: 150,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                    // Item Details
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Item Title
                                          Text(
                                            item.title,
                                            style: AppColors.subheadingStyle,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 8),

                                          // Item Price
                                          if (!hidePrice)
                                            Row(
                                              children: [
                                                Text(
                                                  '₺${item.price.toStringAsFixed(2)}',
                                                  style: AppColors.priceStyle,
                                                ),
                                                if (item.category == 'Rent' &&
                                                    item.paymentPlan != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 8.0),
                                                    child: Text(
                                                      item.paymentPlan!,
                                                      style: GoogleFonts.nunito(
                                                        fontSize: 14,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        color:
                                                            AppColors.textLight,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          SizedBox(height: 12),

                                          // Item Tags
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              Chip(
                                                label: Text(
                                                  item.category,
                                                  style: AppColors.chipStyle,
                                                ),
                                                backgroundColor: AppColors
                                                    .primaryYellow
                                                    .withOpacity(0.7),
                                              ),
                                              Chip(
                                                label: Text(
                                                  item.condition,
                                                  style: AppColors.chipStyle,
                                                ),
                                                backgroundColor: AppColors
                                                    .primaryYellow
                                                    .withOpacity(0.7),
                                              ),
                                              if (item.departments is List &&
                                                  (item.departments as List)
                                                      .isNotEmpty)
                                                Chip(
                                                  label: Text(
                                                    (item.departments as List)
                                                        .first
                                                        .toString(),
                                                    style: AppColors.chipStyle,
                                                  ),
                                                  backgroundColor: AppColors
                                                      .primaryYellow
                                                      .withOpacity(0.7),
                                                ),
                                              if (item.departments is List &&
                                                  (item.departments as List)
                                                          .length >
                                                      1)
                                                Chip(
                                                  label: Text(
                                                    "+${(item.departments as List).length - 1} more",
                                                    style: AppColors.chipStyle,
                                                  ),
                                                  backgroundColor: AppColors
                                                      .primaryYellow
                                                      .withOpacity(0.7),
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
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: Text(
              'No data available',
              style: AppColors.bodyStyle,
            ),
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
          selectedItemColor: AppColors.primaryYellow,
          unselectedItemColor: AppColors.textLight,
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
                icon: FaIcon(FontAwesomeIcons.shop), label: 'Items'),
            BottomNavigationBarItem(
                icon: Icon(Icons.assignment), label: 'Requests'),
            BottomNavigationBarItem(
                icon: Icon(Icons.report), label: 'Complaints'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart), label: 'Analysis'),
            BottomNavigationBarItem(
                icon: Icon(Icons.account_circle), label: 'Profile'),
          ],
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primaryYellow,
          size: 24,
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: AppColors.smallStyle,
        ),
      ],
    );
  }

  void _onItemTapped(int index) {
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

  void _showUnbanDialog(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Unban User',
            style: AppColors.subheadingStyle,
          ),
          content: Text(
            'Are you sure you want to unban this user?',
            style: AppColors.bodyStyle,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.nunito(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Proceed with the unban operation
                _adminController.unbanUser(userId);
                Navigator.of(context).pop(); // Close the dialog after unbanning
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                'Unban',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show the dialog for banning a user
  void _showBanDialog(String userId) {
    // Reset the state of the dialog by clearing previous selections
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Ban User',
                style: AppColors.subheadingStyle,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ban reason dropdown
                    Text(
                      'Ban Reason',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
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
                            color: AppColors.textLight,
                          ),
                        ),
                        isExpanded: true,
                        underline: SizedBox(),
                        style: GoogleFonts.nunito(
                          color: AppColors.textDark,
                          fontSize: 16,
                        ),
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
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Explanation field for "Other" reason
                    if (_selectedBanReason == 'Other')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Explanation',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
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
                              hintText: 'Please provide details',
                              hintStyle: GoogleFonts.nunito(
                                  color: AppColors.textLight),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: AppColors.primaryYellow, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            style:
                                GoogleFonts.nunito(color: AppColors.textDark),
                            maxLines: 3,
                          ),
                          SizedBox(height: 16),
                        ],
                      ),

                    // Ban duration dropdown
                    Text(
                      'Ban Duration',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(12),
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
                            color: AppColors.textLight,
                          ),
                        ),
                        isExpanded: true,
                        underline: SizedBox(),
                        style: GoogleFonts.nunito(
                          color: AppColors.textDark,
                          fontSize: 16,
                        ),
                        items: <String>[
                          'Permanent',
                          '7 days',
                          '10 days',
                          '15 days',
                          '30 days'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
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
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: (_selectedBanReason == null ||
                          _selectedBanDuration == null ||
                          (_selectedBanReason == 'Other' &&
                              _banExplanation.isEmpty))
                      ? null // Disable button if required fields are not filled
                      : () {
                          // Call the ban user method
                          _adminController.banUser(
                            userId: userId,
                            banReason: _selectedBanReason!,
                            explanation: _banExplanation,
                            banPeriod: _selectedBanDuration!,
                          );
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  ),
                  child: Text(
                    'Ban User',
                    style: GoogleFonts.nunito(
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
