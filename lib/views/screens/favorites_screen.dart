import 'package:bees/views/screens/detailed_item_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/home_controller.dart';
import 'message_list_screen.dart';
import 'package:google_fonts/google_fonts.dart';

// Define theme colors
class AppColors {
  static const Color primaryYellow = Color(0xFFFFC857);
  static const Color lightYellow = Color(0xFFFFE3A9);
  static const Color backgroundColor = Color(0xFFF8F8F8);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF8A8A8A);
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _selectedIndex = 2;
  List<DocumentSnapshot> favoriteItems = [];
  bool isLoading = true;

  final HomeController _controller = HomeController();

  @override
  void initState() {
    super.initState();
    fetchFavorites();
  }

  void fetchFavorites() async {
    setState(() => isLoading = true);
    final allFavorites = await _controller.fetchFavorites();
    favoriteItems = allFavorites.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['itemStatus'] != null && data['itemStatus'].toLowerCase() == 'active';
    }).toList();
    setState(() => isLoading = false);
  }

  void _toggleFavorite(String itemId, bool isFavorited) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await _controller.updateFavoriteCount(itemId, isFavorited, userId);
    fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Text(
            'BEES',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryYellow,
            ),
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageListScreen(),
                ),
              );
            },
            color: AppColors.textDark,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
          : favoriteItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: AppColors.textLight),
                      const SizedBox(height: 16),
                                          Text(
                                'No favorite items found',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  color: AppColors.textLight,
                                ),
                                textAlign: TextAlign.center,
                              ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListView.builder(
                    itemCount: favoriteItems.length,
                    itemBuilder: (context, index) {
                      var item = favoriteItems[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailedItemScreen(itemId: item['itemId']),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    item['photo'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item['title'],
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 16,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Text(
                                            '₺${item['price']}',
                                            style: GoogleFonts.nunito(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          if (item['category'] == 'Rent')
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8.0),
                                              child: Text(
                                              item['paymentPlan'],
                                              style: GoogleFonts.nunito(
                                                color: AppColors.textLight,
                                              ),
                                            ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              _buildTag(item['category'], AppColors.lightYellow),
                                              _buildTag(item['condition'], AppColors.lightYellow),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _buildDepartmentsTag(item['departments']),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.favorite, color: Colors.red),
                                      onPressed: () {
                                        _toggleFavorite(item['itemId'], false);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primaryYellow,
        unselectedItemColor: AppColors.textLight,
        currentIndex: _selectedIndex,
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

  Widget _buildTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
  text,
  style: GoogleFonts.nunito(
    color: AppColors.textDark,
    fontWeight: FontWeight.w500,
    fontSize: 12,
  ),
),

    );
  }

  Widget _buildDepartmentsTag(List<dynamic> departments) {
    if (departments.isEmpty) return Container();

    List<String> visibleDepartments = departments.map((e) => e.toString()).take(1).toList();

    if (departments.length > 1) {
      visibleDepartments.add('...');
    }

    return Row(
      children: visibleDepartments.map((department) {
        return _buildTag(department, AppColors.primaryYellow);
      }).toList(),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
        break;
      case 1:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => RequestsScreen()));
        break;
      case 3:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => UserProfileScreen()));
        break;
    }
  }
}