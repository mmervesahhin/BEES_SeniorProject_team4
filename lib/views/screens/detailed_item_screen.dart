import 'package:bees/controllers/reported_item_controller.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/reported_item_model.dart';
import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/message_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:bees/views/screens/others_user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bees/controllers/detailed_item_controller.dart';
import 'package:bees/controllers/home_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

// Define theme colors
class AppColors {
  static const Color primaryYellow = Color(0xFFFFC857);
  static const Color lightYellow = Color(0xFFFFE3A9);
  static const Color backgroundColor = Color(0xFFF8F8F8);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF8A8A8A);
  
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

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchFavoriteStatus();
  }

  Future<void> _fetchData() async {
    print("Fetching details for itemId: ${widget.itemId}");

    Map<String, dynamic>? details = await _controller.fetchItemDetails(widget.itemId);

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

    bool hasReported = await ReportedItemController().hasUserReportedItem(widget.itemId, userIDD);

    if (hasReported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You have already reported this item",
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        "Submit Complaint",
                        style: AppColors.subheadingStyle,
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
                                style: AppColors.bodyStyle,
                              ),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: AppColors.textLight,
                                ),
                                child: RadioListTile<String>(
                                  title: Text(
                                    "Inappropriate for BEES",
                                    style: AppColors.bodyStyle,
                                  ),
                                  value: "Inappropriate for BEES",
                                  groupValue: dialogSelectedReason,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      dialogSelectedReason = value;
                                    });
                                  },
                                  activeColor: AppColors.primaryYellow,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                                ),
                              ),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: AppColors.textLight,
                                ),
                                child: RadioListTile<String>(
                                  title: Text(
                                    "Illegal item",
                                    style: AppColors.bodyStyle,
                                  ),
                                  value: "Illegal item",
                                  groupValue: dialogSelectedReason,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      dialogSelectedReason = value;
                                    });
                                  },
                                  activeColor: AppColors.primaryYellow,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                                ),
                              ),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: AppColors.textLight,
                                ),
                                child: RadioListTile<String>(
                                  title: Text(
                                    "Duplicate item",
                                    style: AppColors.bodyStyle,
                                  ),
                                  value: "Duplicate item",
                                  groupValue: dialogSelectedReason,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      dialogSelectedReason = value;
                                    });
                                  },
                                  activeColor: AppColors.primaryYellow,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 0),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Additional details:",
                                style: AppColors.bodyStyle,
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: complaintController,
                                maxLines: 3,
                                style: AppColors.bodyStyle,
                                decoration: InputDecoration(
                                  hintText: "Enter your reasoning here...",
                                  hintStyle: GoogleFonts.nunito(color: AppColors.textLight),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: AppColors.primaryYellow),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
                              style: GoogleFonts.nunito(color: AppColors.textLight),
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
                              backgroundColor: AppColors.primaryYellow,
                              foregroundColor: AppColors.textDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "Send Report",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
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

  Future<void> _sendReport(String reportReason, String complaintDetails, BuildContext context) async {
    ReportedItemController controller = ReportedItemController();
    final userIDD = FirebaseAuth.instance.currentUser?.uid ?? "defaultUserId"; 
    final itemId = widget.itemId;

    bool alreadyReported = await controller.checkIfAlreadyReported(userIDD, itemId);
    if (alreadyReported) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You have already reported this item",
            style: GoogleFonts.nunito(),
          ),
          backgroundColor: Colors.red,
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
          backgroundColor: AppColors.primaryYellow,
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
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Item Details', 
          style: GoogleFonts.nunito(
            color: AppColors.textDark, 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: AppColors.textDark),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryYellow)))
          : itemDetails == null
              ? Center(child: Text("Item not found", style: AppColors.bodyStyle))
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: itemDetails!["additionalPhotos"] != null && (itemDetails!["additionalPhotos"] as List).isNotEmpty
                                  ? CarouselSlider(
                                      options: CarouselOptions(
                                        height: 250.0, 
                                        autoPlay: true,
                                        viewportFraction: 1.0,
                                      ),
                                      items: [
                                        itemDetails!["photo"],
                                        ...?itemDetails!["additionalPhotos"]
                                      ].map((photo) {
                                        return Builder(
                                          builder: (context) {
                                            return Container(
                                              width: MediaQuery.of(context).size.width,
                                              decoration: BoxDecoration(
                                                image: DecorationImage(
                                                  image: NetworkImage(photo),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }).toList(),
                                    )
                                  : Image.network(
                                      itemDetails!["photo"], 
                                      height: 250, 
                                      width: double.infinity, 
                                      fit: BoxFit.cover,
                                    ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    isFavorited ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorited ? Colors.red : AppColors.textLight,
                                    size: 20,
                                  ),
                                  onPressed: () async {
                                    setState(() {
                                      isFavorited = !isFavorited;
                                    });
                                    _homeController.updateFavoriteCount(widget.itemId, isFavorited, FirebaseAuth.instance.currentUser!.uid);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Text(
                          itemDetails!["title"], 
                          style: AppColors.headingStyle,
                        ),
                        SizedBox(height: 12),
                        if (itemDetails!["price"] != 0) ...[ 
                          Row(
                            children: [
                              Text(
                                '₺${itemDetails!["price"]}',
                                style: AppColors.priceStyle,
                              ),
                              if (itemDetails!["paymentPlan"] != null) ...[ 
                                SizedBox(width: 10),
                                Text(
                                  itemDetails!["paymentPlan"],
                                  style: GoogleFonts.nunito(
                                    fontSize: 16, 
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: 16),
                        ],
                        if (itemDetails!["description"] != null && itemDetails!["description"].toString().trim().isNotEmpty) ...[
                          Text(
                            "Description:", 
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(12),
                            
                            child: Text(
                              
                              itemDetails!["description"],
                              style: GoogleFonts.nunito(
                              fontWeight: FontWeight.normal,
                              color: AppColors.textDark,
                            ),
                              
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        
                        // Departman başlığı ve departman chipleri
                        if (item!.departments != null && (item!.departments as List).isNotEmpty) ...[
                          Text(
                            "Department(s):", 
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: List.generate(itemDetails!["departments"].length, (index) {
                              return Container(
                                width: 100, // Fixed width for all department tags
                                child: Chip(
                                  label: Center(
                                    child: Text(
                                      itemDetails!["departments"][index],
                                      style: AppColors.chipStyle,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  backgroundColor: AppColors.primaryYellow.withOpacity(0.7),
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                ),
                              );
                            }),
                          ),
                          SizedBox(height: 16),
                        ],
                        
                        // Category section
                        Text(
                          "Category:", 
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 8),
                        Chip(
                          label: Text(
                            itemDetails!["category"],
                            style: AppColors.chipStyle,
                          ),
                          backgroundColor: AppColors.primaryYellow.withOpacity(0.7),
                        ),
                        SizedBox(height: 16),
                        
                        // Condition section
                        Text(
                          "Condition:", 
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        SizedBox(height: 8),
                        Chip(
                          label: Text(
                            itemDetails!["condition"],
                            style: AppColors.chipStyle,
                          ),
                          backgroundColor: AppColors.primaryYellow.withOpacity(0.7),
                        ),
                        SizedBox(height: 16),
                        
                        // Item Type if available
                        if (itemDetails!["itemType"] != null && itemDetails!["itemType"].toString().isNotEmpty) ...[
                          Text(
                            "Item Type:", 
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Chip(
                            label: Text(
                              itemDetails!["itemType"],
                              style: AppColors.chipStyle,
                            ),
                            backgroundColor: AppColors.primaryYellow.withOpacity(0.7),
                          ),
                          SizedBox(height: 16),
                        ],
                        
                        // Owner information
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
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (itemDetails!["itemOwnerId"] != null) {
                                    if (itemDetails!["itemOwnerId"] == FirebaseAuth.instance.currentUser!.uid) {
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
                                          builder: (context) => OthersUserProfileScreen(userId: itemDetails!["itemOwnerId"]),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: itemDetails!["ownerProfilePicture"] != null &&
                                              itemDetails!["ownerProfilePicture"].isNotEmpty
                                          ? NetworkImage(itemDetails!["ownerProfilePicture"])
                                          : null,
                                      radius: 24,
                                      backgroundColor: AppColors.lightYellow,
                                      child: itemDetails!["ownerProfilePicture"] == null ||
                                              itemDetails!["ownerProfilePicture"].isEmpty
                                          ? Icon(Icons.person, color: AppColors.textDark)
                                          : null,
                                    ),
                                    SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          itemDetails!["ownerFullName"] != null && itemDetails!["ownerFullName"].isNotEmpty
                                              ? itemDetails!["ownerFullName"]
                                              : "No Name",
                                          style: GoogleFonts.nunito(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Item Owner",
                                          style: GoogleFonts.nunito(
                                            fontSize: 12,
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Spacer(),
                              IconButton(
                                onPressed: () {
                                  _navigateToMessageScreen(item, "Item");
                                },
                                icon: Icon(
                                  Icons.message, 
                                  color: AppColors.primaryYellow, 
                                  size: 28
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Report button with fixes for overflow
                        if (itemDetails!["itemOwnerId"] != FirebaseAuth.instance.currentUser!.uid) ...[
                          Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8, // Limit width to 80% of screen
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _showReportDialog(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red,
                                    elevation: 0,
                                    side: BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  ),
                                  icon: Icon(Icons.report_problem_outlined, size: 18),
                                  label: Text(
                                    "Report Item", 
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryYellow,
        unselectedItemColor: AppColors.textLight,
        selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.nunito(),
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.shop), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
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
          backgroundColor: Colors.red,
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
}