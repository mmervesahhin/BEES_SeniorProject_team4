import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/controllers/home_controller.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _selectedIndex = 2;
  List<DocumentSnapshot> favoriteItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  void _fetchFavorites() async {
    setState(() => isLoading = true);
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      var favoriteItemIds = List<String>.from(userDoc['favoriteItems'] ?? []);

      if (favoriteItemIds.isNotEmpty) {
        var snapshot = await FirebaseFirestore.instance
            .collection('items')
            .where('itemId', whereIn: favoriteItemIds)
            .get();

        setState(() {
          favoriteItems = snapshot.docs;
          isLoading = false;
        });
      } else {
        setState(() {
          favoriteItems = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Favorileri çekerken hata oluştu: $e');
      setState(() => isLoading = false);
    }
  }

  void _toggleFavorite(String itemId, bool isFavorited) async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    await HomeController().updateFavoriteCount(itemId, isFavorited, userId);
    _fetchFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
        automaticallyImplyLeading: false,
        title: const Text(
          'BEES',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.yellow,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteItems.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No favorite items found',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: favoriteItems.length,
                    itemBuilder: (context, index) {
                      var item = favoriteItems[index];
                      
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item['photo'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            item['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '₺${item['price']}',
                                    style: TextStyle(fontSize: 20), 
                                  ),
                                  if (item['category'] == 'Rent') 
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0), // Boşluk ekledik
                                      child: Text(
                                        item['paymentPlan'],
                                      ),
                                    ),
                                ],
                              ),
                              Row(
                                children: [
                                  _buildTag(item['category'], Colors.green),
                                  _buildTag(item['condition'], Colors.yellow),
                                  _buildDepartmentsTag(item['departments']),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.favorite, color: Colors.red),
                            onPressed: () {
                              _toggleFavorite(item['itemId'], false);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 59, 137, 62),
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
      margin: EdgeInsets.only(right: 4),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildDepartmentsTag(List<dynamic> departments) {
    if (departments.isEmpty) return Container();
    
    // List<dynamic>'i List<String>'e dönüştürme
    List<String> visibleDepartments = departments.map((e) => e.toString()).take(1).toList();
    
    if (departments.length > 1) {
      visibleDepartments.add('...');
    }
    
    return Row(
      children: visibleDepartments.map((department) {
        return _buildTag(department, Colors.orange);
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
