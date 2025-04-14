import 'package:bees/views/screens/detailed_item_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/home_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'message_list_screen.dart';

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

  final Color primaryYellow = const Color(0xFFFFC857);
  final Color lightYellow = const Color(0xFFFFE3A9);
  final Color backgroundColor = const Color(0xFFF8F8F8);
  final Color textDark = const Color(0xFF333333);
  final Color textLight = const Color(0xFF8A8A8A);

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Favorites',
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textDark,
          ),
        ),
        iconTheme: IconThemeData(color: textDark),
        actions: [
          IconButton(
            icon: Icon(Icons.message),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MessageListScreen(),
                ),
              );
            },
            color: textDark,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: textLight),
                      SizedBox(height: 16),
                      Text(
                        'No favorite items found',
                        style: GoogleFonts.nunito(fontSize: 18, color: textDark),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add items to your favorites to see them here.',
                        style: GoogleFonts.nunito(fontSize: 16, color: textLight),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12.0),
                  itemCount: favoriteItems.length,
                  itemBuilder: (context, index) {
                    final data = favoriteItems[index].data() as Map<String, dynamic>;
                    final itemId = favoriteItems[index].id;
                    final imageUrl = _controller.getImageUrl(data['photo']);
                    final category = _controller.getCategory(data['category']);
                    final departments = _controller.getDepartments(data['departments']);
                    final condition = data['condition'] ?? 'Unknown';
                    final hidePrice = category.toLowerCase() == 'donation' || category.toLowerCase() == 'exchange';

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
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'],
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (!hidePrice)
                                      Text(
                                        '₺${data['price']}',
                                        style: GoogleFonts.nunito(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: primaryYellow,
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        _buildTag(category, primaryYellow),
                                        _buildTag(condition, lightYellow),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        if (departments.length == 31) // Tüm departmanlar seçiliyse
                                          _buildTag('All Departments', textDark)
                                        else ...[
                                          if (departments.isNotEmpty) _buildTag(departments[0], textDark),
                                          if (departments.length > 1)
                                            _buildTag('+${departments.length - 1}', textDark),
                                        ],
                                      ],
                                    )
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.center,
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
                                    icon: Icon(Icons.favorite, color: Colors.red, size: 16),
                                    onPressed: () {
                                      _toggleFavorite(itemId, false);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryYellow,
        unselectedItemColor: textLight,
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.15),
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