import 'package:bees/controllers/admin_controller.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:bees/views/screens/admin_detailed_item_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/home_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:badges/badges.dart' as badges;

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Color scheme - using the same colors as HomeScreen
  final Color primaryYellow = Color(0xFFFFC857);
  final Color lightYellow = Color(0xFFFFE3A9);
  final Color backgroundColor = Color(0xFFF8F8F8);
  final Color textDark = Color(0xFF333333);
  final Color textLight = Color(0xFF8A8A8A);
  
  List<String> departmentList = [
      'All Departments', 'AMER', 'ARCH', 'CHEM', 'COMD', 'CS', 'CTIS', 'ECON', 'EDU', 'EEE', 'ELIT', 'FA', 'GRA',
      'HART', 'IAED', 'IE', 'IR', 'LAUD', 'LAW', 'MAN', 'MATH', 'MBG', 'ME', 'MSC', 'PHIL', 'PHYS', 'POLS', 'PREP',
      'PSYC', 'THM', 'THR', 'TRIN'
    ];

  List<String> selectedDepartments = [];
                  
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  final HomeController _controller = HomeController();
  final AdminController _controller1 = AdminController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, dynamic> _filters = {
    'priceRange': RangeValues(0, 1000),
    'condition': 'All',
    'category': 'All',
    'itemType': 'All',
    'departments' : [],
  };

  @override
  Widget build(BuildContext context) {
    int activeFilterCount = getActiveFilterCount();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'BEES ',
                style: GoogleFonts.nunito(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: primaryYellow,
                ),
              ),
              TextSpan(
                text: 'admin',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: primaryYellow,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.nunito(
                          color: textDark,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: GoogleFonts.nunito(
                            color: textLight,
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(Icons.search, color: textLight),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: badges.Badge(
                      showBadge: activeFilterCount > 0,
                      badgeContent: Text(
                        activeFilterCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      position: badges.BadgePosition.topEnd(top: -6, end: -6),
                      badgeStyle: const badges.BadgeStyle(
                        badgeColor: Colors.red,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.filter_list, color: Colors.white),
                        onPressed: () {
                          _showFiltersDialog();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
                stream: _controller.getItems(),
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
                      child: Text(
                        'An error occurred: ${snapshot.error}',
                        style: GoogleFonts.nunito(color: textDark),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: textLight,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No items found',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: textLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final items = snapshot.data!.where((doc) {
                    var data = doc.data() as Map<String, dynamic>? ?? {};
                    var title = (data['title'] ?? '').toString().toLowerCase();
                    var price = data['price'] ?? 0;
                    var condition = data['condition'] ?? 'Unknown';
                    var category = data['category'] ?? 'Unknown';
                    var itemType = data['itemType'] ?? 'Unknown';
                    var departments = data['departments'] ?? [];

                    bool matchesSearch = title.contains(_searchQuery);
                    bool matchesFilters = _controller.applyFilters(price, condition, category, itemType, departments, _filters);

                    return matchesSearch && matchesFilters;
                  }).toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: textLight,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No items found',
                            style: GoogleFonts.nunito(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Try adjusting your search or filters',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              color: textLight,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  items.sort((a, b) {
                    var dataA = a.data() as Map<String, dynamic>? ?? {};
                    var dataB = b.data() as Map<String, dynamic>? ?? {};
                    var titleA = (dataA['title'] ?? '').toString().toLowerCase();
                    var titleB = (dataB['title'] ?? '').toString().toLowerCase();
                    return titleA.indexOf(_searchQuery).compareTo(titleB.indexOf(_searchQuery));
                  });

                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.70, // Adjusted for more height
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        var data = items[index].data() as Map<String, dynamic>;
                        String itemId = items[index].id;

                        String imageUrl = _controller.getImageUrl(data['photo']);
                        String category = _controller.getCategory(data['category']);
                        List<String> departments = _controller.getDepartments(data['departments']);
                        String condition = data['condition'] ?? 'Unknown';

                        bool hidePrice = category.toLowerCase() == 'donate' || category.toLowerCase() == 'exchange';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminDetailedItemScreen(itemId: data['itemId']),
                              ),
                            );
                          },
                          child: Container(
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
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image container
                                    Container(
                                      height: 120, // Reduced height
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                        color: backgroundColor,
                                      ),
                                      child: imageUrl.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: BorderRadius.only(
                                                topLeft: Radius.circular(16),
                                                topRight: Radius.circular(16),
                                              ),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: textLight,
                                                size: 40,
                                              ),
                                            ),
                                    ),
                                    
                                    // Item details
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0), // Reduced padding
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['title'],
                                              style: GoogleFonts.nunito(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14, // Smaller font
                                                color: textDark,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 4), // Reduced spacing
                                            SizedBox(
                                              height: 20,
                                              child: hidePrice
                                                  ? SizedBox.shrink()
                                                  : Row(
                                                      children: [
                                                        Text(
                                                          '₺${data['price']}',
                                                          style: GoogleFonts.nunito(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                            color: primaryYellow,
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                        if (data['paymentPlan'] != null)
                                                          Expanded(
                                                            child: Text(
                                                              data['paymentPlan'],
                                                              style: GoogleFonts.nunito(
                                                                fontSize: 10,
                                                                color: textLight,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                            ),
                                            SizedBox(height: 4), // Reduced spacing
                                            
                                            // Tags
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Category & Condition Tags
                                                  Row(
                                                    children: [
                                                      // Category tag
                                                      Flexible(
                                                        child: Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: primaryYellow.withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: primaryYellow),
                                                          ),
                                                          child: Text(
                                                            category,
                                                            style: GoogleFonts.nunito(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                              color: textDark,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 4),
                                                      // Condition tag
                                                      Flexible(
                                                        child: Container(
                                                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                          decoration: BoxDecoration(
                                                            color: lightYellow.withOpacity(0.3),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(color: lightYellow),
                                                          ),
                                                          child: Text(
                                                            condition,
                                                            style: GoogleFonts.nunito(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.bold,
                                                              color: textDark,
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 4),

                                                  // Department Tags
                                                  Row(
                                                    children: [
                                                      if (departments.length == 31)
                                                        Flexible(
                                                          child: Container(
                                                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                            decoration: BoxDecoration(
                                                              color: backgroundColor,
                                                              borderRadius: BorderRadius.circular(8),
                                                              border: Border.all(color: textLight.withOpacity(0.3)),
                                                            ),
                                                            child: Text(
                                                              'All Departments',
                                                              style: GoogleFonts.nunito(
                                                                fontSize: 9,
                                                                fontWeight: FontWeight.bold,
                                                                color: textDark,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                            ),
                                                          ),
                                                        )
                                                      else ...[
                                                        if (departments.isNotEmpty)
                                                          Flexible(
                                                            flex: 2,
                                                            child: Container(
                                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                              decoration: BoxDecoration(
                                                                color: backgroundColor,
                                                                borderRadius: BorderRadius.circular(8),
                                                                border: Border.all(color: textLight.withOpacity(0.3)),
                                                              ),
                                                              child: Text(
                                                                departments[0],
                                                                style: GoogleFonts.nunito(
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: textDark,
                                                                ),
                                                                maxLines: 1,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                          ),
                                                        if (departments.length > 1)
                                                          Flexible(
                                                            flex: 1,
                                                            child: Padding(
                                                              padding: const EdgeInsets.only(left: 4.0),
                                                              child: Container(
                                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                                decoration: BoxDecoration(
                                                                  color: backgroundColor,
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(color: textLight.withOpacity(0.3)),
                                                                ),
                                                                child: Text(
                                                                  '+${departments.length - 1}',
                                                                  style: GoogleFonts.nunito(
                                                                    fontSize: 9,
                                                                    fontWeight: FontWeight.bold,
                                                                    color: textDark,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Admin options button
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: textDark,
                                        size: 16,
                                      ),
                                      onPressed: () {
                                        _controller1.showItemRemoveOptions(context, Item.fromJson(data, itemId));
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 60, // Fixed height
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
            fontSize: 12, // Smaller font
          ),
          unselectedLabelStyle: GoogleFonts.nunito(
            fontSize: 12, // Smaller font
          ),
          iconSize: 22, // Smaller icons
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
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AdminHomeScreen(),
                ));
                break;
              case 1:
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AdminRequestsScreen(),
                ));
                break;
              case 2:
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AdminReportsScreen(),
                ));
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
          },
        ),
      ),
    );
  }

  int getActiveFilterCount() {
    int count = 0;

    if (_filters['minPrice'] != null) count++;
    if (_filters['maxPrice'] != null) count++;
    if (_filters['condition'] != null && _filters['condition'] != 'All') count++;
    if (_filters['itemType'] != null && _filters['itemType'] != 'All') count++;
    if (_filters['category'] != null && _filters['category'] != 'All') count++;
    if ((_filters['departments'] as List).isNotEmpty) count++;

    return count;
  }

  void _showDepartmentDialog(StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        List<String> tempSelection = selectedDepartments.contains('All Departments')
            ? List.from(departmentList)
            : List.from(selectedDepartments);

        return StatefulBuilder(
          builder: (context, innerSetState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Select Departments',
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: primaryYellow),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  children: [
                    CheckboxListTile(
                      value: tempSelection.contains('All Departments'),
                      title: Text('All Departments', style: GoogleFonts.nunito()),
                      onChanged: (bool? value) {
                        innerSetState(() {
                          if (value == true) {
                            tempSelection = List.from(departmentList);
                          } else {
                            tempSelection.clear();
                          }
                        });
                      },
                    ),
                    ...departmentList.where((dept) => dept != 'All Departments').map((dept) {
                      return CheckboxListTile(
                        value: tempSelection.contains(dept),
                        title: Text(dept, style: GoogleFonts.nunito()),
                        onChanged: (bool? value) {
                          innerSetState(() {
                            if (value == true) {
                              tempSelection.add(dept);
                            } else {
                              tempSelection.remove(dept);
                            }

                            bool isAllSelected = tempSelection.contains('All Departments');
                            int normalDeptCount = departmentList.length - 1;
                            int selectedNormal = tempSelection
                                .where((e) => e != 'All Departments')
                                .length;

                            if (selectedNormal == normalDeptCount && !isAllSelected) {
                              tempSelection.add('All Departments');
                            } else if (selectedNormal < normalDeptCount && isAllSelected) {
                              tempSelection.remove('All Departments');
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: primaryYellow,
                    textStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setDialogState(() {
                      selectedDepartments = tempSelection;
                      _filters['departments'] = selectedDepartments.where((d) => d != 'All Departments').toList();
                    });
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryYellow,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFiltersDialog() {
    // Create controllers only once for the dialog
    TextEditingController minPriceController =
        TextEditingController(text: _filters['minPrice']?.toString() ?? '');
    TextEditingController maxPriceController =
        TextEditingController(text: _filters['maxPrice']?.toString() ?? '');
    String errorMessage = ''; // Variable to hold the error message

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8, // Limit height
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Filter Items',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.bold,
                          color: primaryYellow,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price Range Section
                            Text(
                              'Price Range',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: textDark,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: minPriceController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.nunito(color: textDark),
                                    decoration: InputDecoration(
                                      hintText: 'Min Price',
                                      hintStyle: GoogleFonts.nunito(color: textLight),
                                      filled: true,
                                      fillColor: backgroundColor,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: primaryYellow),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        String formatted = value.replaceAll(',', '.');
                                        double? parsed = double.tryParse(formatted);

                                        _filters['minPrice'] = value.isEmpty ? null : parsed;

                                        if (value.isNotEmpty && parsed == null) {
                                          errorMessage = 'Please enter a valid number for Min Price.';
                                        } else {
                                          errorMessage = '';
                                        }
                                      });
                                    },
                                    enabled: _filters['category'] != 'Donation' && _filters['category'] != 'Exchange',
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: maxPriceController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.nunito(color: textDark),
                                    decoration: InputDecoration(
                                      hintText: 'Max Price',
                                      hintStyle: GoogleFonts.nunito(color: textLight),
                                      filled: true,
                                      fillColor: backgroundColor,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: primaryYellow),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        String formatted = value.replaceAll(',', '.');
                                        double? parsed = double.tryParse(formatted);

                                        _filters['maxPrice'] = value.isEmpty ? null : parsed;

                                        if (value.isNotEmpty && parsed == null) {
                                          errorMessage = 'Please enter a valid number for Max Price.';
                                        } else {
                                          errorMessage = '';
                                        }
                                      });
                                    },
                                    enabled: _filters['category'] != 'Donation' && _filters['category'] != 'Exchange',
                                  ),
                                ),
                              ],
                            ),
                            if (errorMessage.isNotEmpty) 
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  errorMessage,
                                  style: GoogleFonts.nunito(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            SizedBox(height: 20),
                            
                            Text(
                              'Departments',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: textDark,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _showDepartmentDialog(setDialogState),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedDepartments.contains('All Departments')
                                        ? 'All Departments'
                                        : selectedDepartments.isEmpty
                                            ? null
                                            : '${selectedDepartments.length} selected',
                                    hint: Text(
                                      'Select Departments',
                                      style: GoogleFonts.nunito(color: textLight),
                                    ),
                                    icon: Icon(Icons.arrow_drop_down, color: primaryYellow),
                                    style: GoogleFonts.nunito(
                                      color: textDark,
                                      fontSize: 14,
                                    ),
                                    onChanged: (_) {
                                      // override dropdown behavior: always open the dialog
                                      _showDepartmentDialog(setDialogState);
                                    },
                                    items: [], // dropdown'u boş bırakıyoruz, çünkü dialog açılacak
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 8),
if (selectedDepartments.isNotEmpty)
  Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      if (selectedDepartments.contains('All Departments'))
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: textLight.withOpacity(0.3)),
          ),
          child: Text(
            'All Departments',
            style: GoogleFonts.nunito(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
        )
      else ...[
        ...selectedDepartments.take(3).map((dept) => Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: textLight.withOpacity(0.3)),
              ),
              child: Text(
                dept,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
            )),
        if (selectedDepartments.length > 3)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: textLight.withOpacity(0.3)),
            ),
            child: Text(
              '+${selectedDepartments.length - 3} more',
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
          ),
      ],
    ],
  ),

                            SizedBox(height: 20),

                            // Condition Section
                            Text(
                              'Condition',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: textDark,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _filters['condition'],
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: primaryYellow),
                                  style: GoogleFonts.nunito(
                                    color: textDark,
                                    fontSize: 14,
                                  ),
                                  dropdownColor: Colors.white,
                                  onChanged: (String? newValue) {
                                    setDialogState(() {
                                      _filters['condition'] = newValue!;
                                    });
                                  },
                                  items: <String>[
                                    'All',
                                    'New',
                                    'Lightly Used',
                                    'Moderately Used',
                                    'Heavily Used'
                                  ].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Item Type Section
                            Text(
                              'Item Type',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: textDark,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _filters['itemType'],
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: primaryYellow),
                                  style: GoogleFonts.nunito(
                                    color: textDark,
                                    fontSize: 14,
                                  ),
                                  dropdownColor: Colors.white,
                                  onChanged: (String? newValue) {
                                    setDialogState(() {
                                      _filters['itemType'] = newValue!;
                                    });
                                  },
                                  items: <String>[
                                    'All',
                                    'Notes',
                                    'Books',
                                    'Electronics',
                                    'Stationery',
                                    'Other'
                                  ].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Category Section
                            Text(
                              'Category',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: textDark,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _filters['category'],
                                  isExpanded: true,
                                  icon: Icon(Icons.arrow_drop_down, color: primaryYellow),
                                  style: GoogleFonts.nunito(
                                    color: textDark,
                                    fontSize: 14,
                                  ),
                                  dropdownColor: Colors.white,
                                  onChanged: (String? newValue) {
                                    setDialogState(() {
                                      _filters['category'] = newValue!;
                                    });
                                  },
                                  items: <String>[
                                    'All',
                                    'Sale',
                                    'Rent',
                                    'Exchange',
                                    'Donation'
                                  ].map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                _filters = {
                                  'minPrice': null,
                                  'maxPrice': null,
                                  'condition': 'All',
                                  'itemType': 'All',
                                  'category': 'All',
                                  'departments': [],
                                };
                                selectedDepartments = [];
                                minPriceController.clear();
                                maxPriceController.clear();
                                errorMessage = ''; // Clear error when filters are cleared

                                // Reset selected departments to none (unselect everything)
                                selectedDepartments = [];
                              });
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: textLight.withOpacity(0.3)),
                              ),
                            ),
                            child: Text(
                              'Clear Filters',
                              style: GoogleFonts.nunito(
                                color: textDark,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Check if min price or max price is negative
                              if ((_filters['minPrice'] != null && _filters['minPrice'] < 0) ||
                                  (_filters['maxPrice'] != null && _filters['maxPrice'] < 0)) {
                                setDialogState(() {
                                  errorMessage = 'Price values cannot be negative!';
                                });
                              } 
                              // Check if min price is greater than max price
                              else if (_filters['minPrice'] != null &&
                                  _filters['maxPrice'] != null &&
                                  _filters['minPrice'] > _filters['maxPrice']) {
                                setDialogState(() {
                                  errorMessage =
                                      'Min price value cannot be smaller than the max price value!';
                                });
                              } else {
                                setState(() {}); // Apply filters globally
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryYellow,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Apply Filters',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
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
}