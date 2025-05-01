import 'package:bees/models/item_model.dart';
import 'package:bees/models/user_model.dart' show User;
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_others_user_profile_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bees/controllers/detailed_item_controller.dart';
import 'package:bees/controllers/admin_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Define theme colors
class AppColors {
  static const Color primaryYellow = Color(0xFFFFC857);
  static const Color lightYellow = Color(0xFFFFE3A9);
  static const Color backgroundColor = Color(0xFFF8F8F8);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF8A8A8A);
  static const Color cardBackground = Colors.white;
  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color accentBlue = Color(0xFF3498db);
  static const Color accentGreen = Color(0xFF2ecc71);
  static const Color accentRed = Color(0xFFe74c3c);
}

class AdminDetailedItemScreen extends StatefulWidget {
  final String itemId;

  const AdminDetailedItemScreen({Key? key, required this.itemId})
      : super(key: key);

  @override
  _AdminDetailedItemScreenState createState() =>
      _AdminDetailedItemScreenState();
}

class _AdminDetailedItemScreenState extends State<AdminDetailedItemScreen> {
  final DetailedItemController _controller = DetailedItemController();
  final AdminController _adminController = AdminController();

  Map<String, dynamic>? itemDetails;
  bool isLoading = true;
  int _currentImageIndex = 0;
  Item? item;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    Map<String, dynamic>? details =
        await _controller.fetchItemDetails(widget.itemId);
    setState(() {
      itemDetails = details;
      isLoading = false;
      if (details != null) {
        item = Item.fromJson(details, widget.itemId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.primaryYellow)))
          : itemDetails == null
              ? Center(
                  child: Text("Item not found",
                      style: GoogleFonts.nunito(fontSize: 18)))
              : CustomScrollView(
                  slivers: [
                    // App Bar
                    _buildSliverAppBar(),

                    // Content
                    SliverToBoxAdapter(
                      child: _buildItemDetails(),
                    ),
                  ],
                ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSliverAppBar() {
    List<String> images = [];
    if (itemDetails!["photo"] != null) {
      images.add(itemDetails!["photo"]);
    }
    if (itemDetails!["additionalPhotos"] != null) {
      images.addAll(List<String>.from(itemDetails!["additionalPhotos"]));
    }

    return SliverAppBar(
      expandedHeight: 300.0,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.more_vert,
              color: AppColors.textDark,
            ),
            onPressed: () {
              _adminController.showItemRemoveOptions(
                context,
                Item.fromJson(itemDetails!, widget.itemId),
                onSuccess: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => AdminHomeScreen()),
                    (route) => false,
                  );
                },
              );
            },
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Image gallery with PageView
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentImageIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                  ),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryYellow),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.error_outline,
                          color: AppColors.textLight,
                          size: 40,
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            // Image indicators
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images.asMap().entries.map((entry) {
                    return Container(
                      width: 8.0,
                      height: 8.0,
                      margin: EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentImageIndex == entry.key
                            ? AppColors.primaryYellow
                            : Colors.white.withOpacity(0.5),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Admin badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "Admin View",
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetails() {
    return Container(
      color: AppColors.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and price section
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itemDetails!["title"],
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(),
                        ],
                      ),
                    ),
                    if (itemDetails!["price"] != 0)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₺${itemDetails!["price"]}',
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryYellow,
                              ),
                            ),
                            if (itemDetails!["paymentPlan"] != null)
                              Text(
                                itemDetails!["paymentPlan"],
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 16),

                // Tags row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTag(itemDetails!["category"], AppColors.accentBlue),
                    _buildTag(itemDetails!["condition"], AppColors.accentGreen),
                    if (itemDetails!["itemType"] != null &&
                        itemDetails!["itemType"].toString().isNotEmpty)
                      _buildTag(
                          itemDetails!["itemType"], AppColors.primaryYellow),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Description section
          if (itemDetails!["description"] != null &&
              itemDetails!["description"].toString().trim().isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Description",
                    style: GoogleFonts.nunito(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    itemDetails!["description"],
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      color: AppColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(height: 8),

          // Departments section
          if (item!.departments != null &&
              (item!.departments as List).isNotEmpty)
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: AppColors.primaryYellow),
                      SizedBox(width: 8),
                      Text(
                        "Departments",
                        style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  _buildCompactDepartmentsList(itemDetails!["departments"]),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.dividerColor),
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              children:
                  List.generate(itemDetails!["departments"].length, (index) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: index < itemDetails!["departments"].length - 1
                          ? 8
                          : 0),
                );
              }),
            ),
          ),

          SizedBox(height: 8),

          // Owner information
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Seller Information",
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (itemDetails!["itemOwnerId"] != null) {
                          if (itemDetails!["itemOwnerId"] ==
                              FirebaseAuth.instance.currentUser!.uid) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminProfileScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminOthersUserProfileScreen(
                                        userId: itemDetails!["itemOwnerId"]),
                              ),
                            );
                          }
                        }
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                itemDetails!["ownerProfilePicture"] != null &&
                                        itemDetails!["ownerProfilePicture"]
                                            .isNotEmpty
                                    ? NetworkImage(
                                        itemDetails!["ownerProfilePicture"])
                                    : null,
                            radius: 24,
                            backgroundColor: AppColors.lightYellow,
                            child: itemDetails!["ownerProfilePicture"] ==
                                        null ||
                                    itemDetails!["ownerProfilePicture"].isEmpty
                                ? Icon(Icons.person,
                                    color: AppColors.primaryYellow)
                                : null,
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemDetails!["ownerFullName"] != null &&
                                        itemDetails!["ownerFullName"].isNotEmpty
                                    ? itemDetails!["ownerFullName"]
                                    : "No Name",
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: AppColors.textLight,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "Item Owner",
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminOthersUserProfileScreen(
                                userId: itemDetails!["itemOwnerId"]),
                          ),
                        );
                      },
                      icon: Icon(Icons.visibility, size: 18),
                      label: Text(
                        "View Profile",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Admin actions
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        color: AppColors.accentBlue),
                    SizedBox(width: 8),
                    Text(
                      "Admin Actions",
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _adminController.showItemRemoveOptions(context,
                              Item.fromJson(itemDetails!, widget.itemId));
                        },
                        icon: Icon(Icons.delete, size: 18),
                        label: Text(
                          "Remove Item",
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRed,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bottom padding
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildCompactDepartmentsList(List<dynamic> departments) {
    if (departments.length <= 3) {
      // If there are only 1-3 departments, show them all
      return Text(
        departments.join(", "),
        style: GoogleFonts.nunito(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textDark,
        ),
      );
    } else {
      // If there are more than 3 departments, show first 3 + count of remaining
      return Row(
        children: [
          Text(
            "${departments[0]}, ${departments[1]}, ${departments[2]}",
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
          SizedBox(width: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              "+${departments.length - 3}",
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
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
}
