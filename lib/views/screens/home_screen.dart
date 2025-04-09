import 'package:bees/controllers/message_controller.dart';
import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/item_upload_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:bees/views/screens/detailed_item_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/home_controller.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'message_list_screen.dart';
import 'package:bees/views/screens/notification_screen.dart';
import 'package:badges/badges.dart' as badges;


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Color scheme
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
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final HomeController _controller = HomeController();
  final TextEditingController _searchController = TextEditingController();
  Map<String, bool> _favorites = {};
  String _searchQuery = '';
  Map<String, dynamic> _filters = {
    'priceRange': RangeValues(0, 1000),
    'condition': 'All',
    'category': 'All',
    'itemType': 'All',
    'departments' : [],
  };

    @override
   void initState() {
     super.initState();
     // Favori öğeleri alıyoruz
     fetchAndSetFavorites();
   }
 
   Future<void> fetchAndSetFavorites() async {
     try {
       // HomeController'dan fetchFavorites çağrılır
       List<DocumentSnapshot> favoriteItems = await _controller.fetchFavorites();
 
       // Favori öğeleri Map'e dolduruyoruz, her öğe 'true' olarak işaretlenir
       setState(() {
         _favorites = {
           for (var doc in favoriteItems) doc.id: true
         };
       });
     } catch (e) {
       print('Hata: $e');
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
        title: Text(
          'BEES',
          style: GoogleFonts.nunito(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: primaryYellow,
          ),
        ),
        actions: [
        StreamBuilder<int>(
            stream: MessageController().getTotalUnreadMessagesCount(currentUserId), // Stream tüm chat room'lar için toplamı döndürecek
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (snapshot.hasData) {
                int unreadMessages = snapshot.data ?? 0;

                return IconButton(
                  icon: badges.Badge(
                    showBadge: unreadMessages > 0,
                    badgeContent: Text(
                      unreadMessages.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    child: const Icon(Icons.message, size: 24),
                    badgeStyle: const badges.BadgeStyle(
                      badgeColor: Colors.red,
                    ),
                  ),
                  color: Color(0xFF333333), // textDark
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageListScreen(),
                      ),
                    ).then((_) {
                      // Geri dönüldüğünde verileri yenilemek için Stream yeniden çalıştırılır
                      setState(() {});
                    });
                  },
                );
              } else {
                return Container(); // Eğer data yoksa boş bir widget döndür
              }
            },
          ),



          StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('notifications')
      .where('receiverId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
      .where('isRead', isEqualTo: false)
      .snapshots(),
  builder: (context, snapshot) {
    int unreadCount = snapshot.data?.docs.length ?? 0;

    return IconButton(
      icon: badges.Badge(
        showBadge: unreadCount > 0,
        badgeContent: Text(
          unreadCount.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        child: const Icon(Icons.notifications),
        badgeStyle: const badges.BadgeStyle(
          badgeColor: Colors.red,
        ),
      ),
      color: textDark,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        );
      },
    );
  },
),

        ],
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
                    child: IconButton(
                      icon: Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {
                        _showFiltersDialog();
                      },
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
                        childAspectRatio: 0.75, // Adjusted for more height
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        var data = items[index].data() as Map<String, dynamic>;
                        String itemId = items[index].id;

                        bool isFavorited = _favorites[itemId] ?? false;

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
                                builder: (context) => DetailedItemScreen(itemId: data['itemId']),
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
                                            if (!hidePrice)
                                              Row(
                                                children: [
                                                  Text(
                                                    '₺${data['price']}',
                                                    style: GoogleFonts.nunito(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14, // Smaller font
                                                      color: primaryYellow,
                                                    ),
                                                  ),
                                                  SizedBox(width: 4), // Reduced spacing
                                                  if (data['paymentPlan'] != null)
                                                    Expanded(
                                                      child: Text(
                                                        data['paymentPlan'],
                                                        style: GoogleFonts.nunito(
                                                          fontSize: 10, // Smaller font
                                                          color: textLight,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            SizedBox(height: 4), // Reduced spacing
                                            
                                            // Tags
                                            Expanded(
                                              child: SingleChildScrollView(
                                                child: Wrap(
                                                  spacing: 2, // Reduced spacing
                                                  runSpacing: 2, // Reduced spacing
                                                  children: [
                                                    // Category tag
                                                    Container(
                                                      margin: EdgeInsets.only(bottom: 2, right: 2),
                                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                                                      decoration: BoxDecoration(
                                                        color: primaryYellow.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(8), // Smaller radius
                                                        border: Border.all(
                                                          color: primaryYellow,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        category,
                                                        style: GoogleFonts.nunito(
                                                          fontSize: 8, // Smaller font
                                                          fontWeight: FontWeight.bold,
                                                          color: textDark,
                                                        ),
                                                      ),
                                                    ),
                                                    
                                                    // Condition tag
                                                    Container(
                                                      margin: EdgeInsets.only(bottom: 2, right: 2),
                                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                                                      decoration: BoxDecoration(
                                                        color: lightYellow.withOpacity(0.3),
                                                        borderRadius: BorderRadius.circular(8), // Smaller radius
                                                        border: Border.all(
                                                          color: lightYellow,
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        condition,
                                                        style: GoogleFonts.nunito(
                                                          fontSize: 8, // Smaller font
                                                          fontWeight: FontWeight.bold,
                                                          color: textDark,
                                                        ),
                                                      ),
                                                    ),
                                                    
                                                    // Department tag (first one only)
                                                    if (departments.isNotEmpty)
                                                      Container(
                                                        margin: EdgeInsets.only(bottom: 2, right: 2),
                                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                                                        decoration: BoxDecoration(
                                                          color: backgroundColor,
                                                          borderRadius: BorderRadius.circular(8), // Smaller radius
                                                          border: Border.all(
                                                            color: textLight.withOpacity(0.3),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          departments[0],
                                                          style: GoogleFonts.nunito(
                                                            fontSize: 8, // Smaller font
                                                            fontWeight: FontWeight.bold,
                                                            color: textDark,
                                                          ),
                                                        ),
                                                      ),
                                                      
                                                    // More departments indicator
                                                    if (departments.length > 1)
                                                      Container(
                                                        margin: EdgeInsets.only(bottom: 2),
                                                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Reduced padding
                                                        decoration: BoxDecoration(
                                                          color: backgroundColor,
                                                          borderRadius: BorderRadius.circular(8), // Smaller radius
                                                          border: Border.all(
                                                            color: textLight.withOpacity(0.3),
                                                            width: 1,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          '+${departments.length - 1}',
                                                          style: GoogleFonts.nunito(
                                                            fontSize: 8, // Smaller font
                                                            fontWeight: FontWeight.bold,
                                                            color: textDark,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Favorite button
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 32, // Smaller size
                                    height: 32, // Smaller size
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
                                        isFavorited ? Icons.favorite : Icons.favorite_border,
                                        color: isFavorited ? Colors.red : textLight,
                                        size: 16, // Smaller icon
                                      ),
                                      onPressed: () async {
                                        setState(() {
                                          _favorites[itemId] = !isFavorited;
                                        });
                                        _controller.updateFavoriteCount(itemId, !isFavorited, userId!);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadItemPage()),
          );
        },
        backgroundColor: primaryYellow,
        child: Icon(Icons.add, color: Colors.white),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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
              icon: Icon(Icons.favorite),
              label: 'Favorites',
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
                  builder: (context) => HomeScreen(),
                ));
                break;
              case 1:
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => RequestsScreen(),
                ));
                break;
              case 2:
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => FavoritesScreen(),
                ));
                break;
              case 3:
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => UserProfileScreen(),
                ));
                break;
            }
          },
        ),
      ),
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
                                        _filters['minPrice'] = value.isEmpty ? null : double.tryParse(value);
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
                                        _filters['maxPrice'] = value.isEmpty ? null : double.tryParse(value);
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
                            
                            // Departments Section
                            Text(
                              'Departments',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.bold,
                                color: textDark,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Theme(
                              data: Theme.of(context).copyWith(
                                textTheme: TextTheme(
                                  titleMedium: GoogleFonts.nunito(
                                    color: textDark,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              child: MultiSelectDialogField(
                                title: Text(
                                  'Select Departments',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.bold,
                                    color: textDark,
                                  ),
                                ),
                                buttonText: Text(
                                  'Select Departments',
                                  style: GoogleFonts.nunito(
                                    color: textLight,
                                  ),
                                ),
                                buttonIcon: Icon(Icons.arrow_drop_down, color: primaryYellow),
                                decoration: BoxDecoration(
                                  color: backgroundColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                selectedColor: primaryYellow,
                                checkColor: Colors.white,
                                unselectedColor: textLight,
                                items: departmentList.map((e) => MultiSelectItem(e, e)).toList(),
                                initialValue: selectedDepartments.where((dept) => dept != 'All Departments').toList(),
                                onConfirm: (values) {
                                  setDialogState(() {
                                    selectedDepartments = values;

                                    // If 'All Departments' is selected, select all departments and remove 'All Departments' from the list
                                    if (selectedDepartments.contains('All Departments')) {
                                      selectedDepartments = List.from(departmentList);
                                      // selectedDepartments.remove('All Departments');
                                    }

                                    // If no departments are selected, add 'All Departments' to the list
                                    if (selectedDepartments.isEmpty) {
                                      selectedDepartments.add('All Departments');
                                    }

                                    // Update the _filters['departments'] with the selected departments
                                    _filters['departments'] = selectedDepartments;
                                  });
                                },
                                onSelectionChanged: (selectedList) {
                                  setDialogState(() {
                                    if (selectedList.contains('All Departments') && selectedList.length == departmentList.length) {
                                      // Keep 'All Departments' selected if all are selected
                                      selectedDepartments = List.from(departmentList);
                                    } else if (!selectedList.contains('All Departments')) {
                                      // Uncheck 'All Departments' if not all are selected
                                      selectedDepartments = selectedList;
                                    }

                                    // Update _filters['departments'] whenever selection changes
                                    _filters['departments'] = selectedDepartments;
                                  });
                                },
                              ),
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
                                  'selectedDepartments': [],
                                };
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