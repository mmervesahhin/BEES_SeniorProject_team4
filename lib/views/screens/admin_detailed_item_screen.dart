import 'package:bees/models/item_model.dart';
import 'package:bees/models/user_model.dart' show User;
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_others_user_profile_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:bees/views/screens/message_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:bees/controllers/detailed_item_controller.dart';
import 'package:bees/controllers/admin_controller.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';

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

class AdminDetailedItemScreen extends StatefulWidget {
  final String itemId;

  const AdminDetailedItemScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  _AdminDetailedItemScreenState createState() => _AdminDetailedItemScreenState();
}

class _AdminDetailedItemScreenState extends State<AdminDetailedItemScreen> {
  String? selectedReportReason = "Inappropriate for BEES"; // Initial value
  TextEditingController complaintController = TextEditingController();

  final DetailedItemController _controller = DetailedItemController();
  final AdminController _controller1 = AdminController();

  Map<String, dynamic>? itemDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    Map<String, dynamic>? details = await _controller.fetchItemDetails(widget.itemId);
    setState(() {
      itemDetails = details;
      isLoading = false;
    });
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
                                    Icons.more_vert,
                                    color: AppColors.textDark,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _controller1.showItemRemoveOptions(
                                      context, 
                                      Item.fromJson(itemDetails!, widget.itemId)
                                    );
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
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.backgroundColor, width: 1),
                            ),
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
                        
                        // Department section
                        if (itemDetails!["departments"] != null && (itemDetails!["departments"] as List).isNotEmpty) ...[
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
                                          builder: (context) => AdminProfileScreen(),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AdminOthersUserProfileScreen(userId: itemDetails!["itemOwnerId"]),
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
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Admin actions
                        Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Center(
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _controller1.showItemRemoveOptions(
                                    context, 
                                    Item.fromJson(itemDetails!, widget.itemId)
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryYellow,
                                  foregroundColor: AppColors.textDark,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                ),
                                icon: Icon(Icons.admin_panel_settings, size: 18),
                                label: Text(
                                  "Admin Actions", 
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ),
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
            BottomNavigationBarItem(icon: FaIcon(FontAwesomeIcons.shop), label: 'Items'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Complaints'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analysis'),
            BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
          ],
          onTap: _onItemTapped,
        ),
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