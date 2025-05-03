import 'package:bees/controllers/reported_item_controller.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/reported_item_model.dart';
import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/message_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:bees/views/screens/others_user_profile_screen.dart';
import 'package:bees/views/screens/edit_item_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bees/controllers/detailed_item_controller.dart';
import 'package:bees/controllers/home_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

class DetailedItemScreen extends StatefulWidget {
  final String itemId;

  const DetailedItemScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  _DetailedItemScreenState createState() => _DetailedItemScreenState();
}

class _DetailedItemScreenState extends State<DetailedItemScreen> {
  String? selectedReportReason = "Inappropriate for BEES";
  TextEditingController complaintController = TextEditingController();

  final DetailedItemController _controller = DetailedItemController();
  final HomeController _homeController = HomeController();
  Item? item;

  Map<String, dynamic>? itemDetails;
  bool isLoading = true;
  bool isFavorited = false;
  bool hasFavoriteChanged = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchFavoriteStatus();
  }

  Future<void> _fetchData() async {
    print("Fetching details for itemId: ${widget.itemId}");

    Map<String, dynamic>? details =
        await _controller.fetchItemDetails(widget.itemId);

    if (details == null) {
      print("Item not found in Firestore!");
    } else {
      print("Fetched details: $details");
    }

    if (mounted) {
      setState(() {
        itemDetails = details;
        isLoading = false;
        item = Item.fromJson(itemDetails!, widget.itemId);
      });

      print(item);
    }
  }

  Future<void> _fetchFavoriteStatus() async {
    bool status = await _homeController.fetchFavoriteStatus(widget.itemId);
    setState(() {
      isFavorited = status;
    });
  }

  Future<void> _showReportDialog(BuildContext context) async {
    String? dialogSelectedReason = selectedReportReason;

    final userIDD = FirebaseAuth.instance.currentUser?.uid ?? "defaultUserId";

    bool hasReported = await ReportedItemController()
        .hasUserReportedItem(widget.itemId, userIDD);

    if (hasReported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You have already reported this item",
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.report_problem_outlined,
                              color: AppColors.accentRed),
                          SizedBox(width: 8),
                          Text(
                            "Report Item",
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Please select a reason:",
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: AppColors.textLight,
                                ),
                                child: RadioListTile<String>(
                                  title: Text(
                                    "Inappropriate for BEES",
                                    style: GoogleFonts.nunito(
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  value: "Inappropriate for BEES",
                                  groupValue: dialogSelectedReason,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      dialogSelectedReason = value;
                                    });
                                  },
                                  activeColor: AppColors.primaryYellow,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 0),
                                ),
                              ),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: AppColors.textLight,
                                ),
                                child: RadioListTile<String>(
                                  title: Text(
                                    "Illegal item",
                                    style: GoogleFonts.nunito(
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  value: "Illegal item",
                                  groupValue: dialogSelectedReason,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      dialogSelectedReason = value;
                                    });
                                  },
                                  activeColor: AppColors.primaryYellow,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 0),
                                ),
                              ),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: AppColors.textLight,
                                ),
                                child: RadioListTile<String>(
                                  title: Text(
                                    "Duplicate item",
                                    style: GoogleFonts.nunito(
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  value: "Duplicate item",
                                  groupValue: dialogSelectedReason,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      dialogSelectedReason = value;
                                    });
                                  },
                                  activeColor: AppColors.primaryYellow,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 0),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Additional details:",
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: complaintController,
                                maxLines: 3,
                                style: GoogleFonts.nunito(
                                  color: AppColors.textDark,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Enter your reasoning here...",
                                  hintStyle: GoogleFonts.nunito(
                                      color: AppColors.textLight),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: AppColors.dividerColor),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColors.primaryYellow),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: AppColors.dividerColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.nunito(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                selectedReportReason = dialogSelectedReason;
                              });

                              if (selectedReportReason != null) {
                                await _sendReport(
                                  selectedReportReason!,
                                  complaintController.text,
                                  context,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Please select a report reason",
                                      style: GoogleFonts.nunito(),
                                    ),
                                  ),
                                );
                              }
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Submit Report",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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
    );
  }

  Future<void> _sendReport(String reportReason, String complaintDetails,
      BuildContext context) async {
    ReportedItemController controller = ReportedItemController();
    final userIDD = FirebaseAuth.instance.currentUser?.uid ?? "defaultUserId";
    final itemId = widget.itemId;

    bool alreadyReported =
        await controller.checkIfAlreadyReported(userIDD, itemId);
    if (alreadyReported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You have already reported this item",
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ReportedItem reportedItem = ReportedItem(
      complaintID: DateTime.now().millisecondsSinceEpoch,
      complaintDetails: complaintDetails,
      reportReason: reportReason,
      reportedBy: userIDD,
      itemId: itemId,
    );

    try {
      await controller.reportItem(reportedItem);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Item has been reported successfully!",
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: AppColors.accentGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error reporting item: $e",
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      bottomNavigationBar: _buildBottomBar(),
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
            Navigator.pop(context, hasFavoriteChanged);
          },
        ),
      ),
      actions: [
        if (itemDetails!["itemOwnerId"] !=
            FirebaseAuth.instance.currentUser!.uid)
          Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.report_problem_outlined,
                color: AppColors.accentRed,
              ),
              onPressed: () {
                _showReportDialog(context);
              },
              tooltip: "Report Item",
            ),
          ),
        Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and price section with improved layout
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                    if (itemDetails!["price"] != 0)
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primaryYellow.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₺${itemDetails!["price"]}',
                              style: GoogleFonts.nunito(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryYellow,
                              ),
                            ),
                            if (itemDetails!["paymentPlan"] != null)
                              Container(
                                margin: EdgeInsets.only(top: 2),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  itemDetails!["paymentPlan"],
                                  style: GoogleFonts.nunito(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 20),

                // Tags row with improved styling
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Item Details",
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildEnhancedTag(itemDetails!["category"],
                            AppColors.accentBlue, Icons.category_outlined),
                        _buildEnhancedTag(
                            itemDetails!["condition"],
                            AppColors.accentGreen,
                            Icons.auto_fix_high_outlined),
                        if (itemDetails!["itemType"] != null &&
                            itemDetails!["itemType"].toString().isNotEmpty)
                          _buildEnhancedTag(itemDetails!["itemType"],
                              AppColors.primaryYellow, Icons.style_outlined),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 12),

          // Description section
          if (itemDetails!["description"] != null &&
              itemDetails!["description"].toString().trim().isNotEmpty)
            Container(
              width: double.infinity,
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

          // Departments section - UPDATED TO USE EXPANSION TILE
          if (item!.departments != null &&
              (item!.departments as List).isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child:
                  _buildDepartmentsExpansionTile(itemDetails!["departments"]),
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
                Row(children: [
                  GestureDetector(
                    onTap: () {
                      if (itemDetails!["itemOwnerId"] != null) {
                        if (itemDetails!["itemOwnerId"] ==
                            FirebaseAuth.instance.currentUser!.uid) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OthersUserProfileScreen(
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
                          child: itemDetails!["ownerProfilePicture"] == null ||
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
                                  Icons.verified_user,
                                  size: 14,
                                  color: AppColors.accentGreen,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  "Verified Seller",
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: AppColors.accentGreen,
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
                ]),
              ],
            ),
          ),

          SizedBox(height: 8),

          // Safety tips
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: AppColors.primaryYellow),
                    SizedBox(width: 8),
                    Text(
                      "Safety Tips",
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildSafetyTip("Meet in a public place"),
                _buildSafetyTip("Check the item before paying"),
                _buildSafetyTip("Don't share personal information"),
              ],
            ),
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  // New method to display departments with ExpansionTile
  Widget _buildDepartmentsExpansionTile(List<dynamic> departments) {
    String compactDisplay = "";

    if (departments.length <= 2) {
      compactDisplay = departments.join(", ");
    } else {
      compactDisplay =
          "${departments[0]}, ${departments[1]}, +${departments.length - 2}";
    }

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        title: Row(
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
        subtitle: Text(
          compactDisplay,
          style: GoogleFonts.nunito(
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
        childrenPadding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        tilePadding: EdgeInsets.zero,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: departments.map((department) {
              return Chip(
                label: Text(
                  department,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
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

  Widget _buildSafetyTip(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: AppColors.accentGreen,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (itemDetails == null) return SizedBox.shrink();

    // If current user is the owner, show different bottom bar
    if (itemDetails!["itemOwnerId"] == FirebaseAuth.instance.currentUser!.uid) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to edit item screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditItemScreen(item: item!),
                    ),
                  );
                },
                icon: Icon(Icons.edit),
                label: Text(
                  "Edit Item",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
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
      );
    }

    // Regular bottom bar for non-owners
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryYellow),
            ),
            child: IconButton(
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color:
                    isFavorited ? AppColors.accentRed : AppColors.primaryYellow,
              ),
              onPressed: () async {
                setState(() {
                  isFavorited = !isFavorited;
                  hasFavoriteChanged = true;
                });
                _homeController.updateFavoriteCount(widget.itemId, isFavorited,
                    FirebaseAuth.instance.currentUser!.uid);
              },
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _navigateToMessageScreen(item, "Item");
              },
              icon: Icon(Icons.message),
              label: Text(
                "Contact Seller",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryYellow,
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
          backgroundColor: AppColors.accentRed,
          behavior: SnackBarBehavior.floating,
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

  Widget _buildEnhancedTag(String text, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
