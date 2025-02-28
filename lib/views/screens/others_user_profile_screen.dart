import 'package:bees/views/screens/detailed_item_screen.dart';
import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; 

class OthersUserProfileScreen extends StatefulWidget {
  final String userId;

  const OthersUserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _OthersUserProfileScreenState createState() => _OthersUserProfileScreenState();
}

class _OthersUserProfileScreenState extends State<OthersUserProfileScreen> {
  late Future<DocumentSnapshot> userProfileData;
  late Future<List<DocumentSnapshot>> activeItems;

  @override
  void initState() {
    super.initState();
    userProfileData = FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    activeItems = fetchActiveItems();
  }

  Future<List<DocumentSnapshot>> fetchActiveItems() async {
    var items = await FirebaseFirestore.instance
        .collection('items')
        .where('itemOwnerId', isEqualTo: widget.userId)
        .where('itemStatus', isEqualTo: 'active')
        .get();
    return items.docs;
  }

  Widget _buildTag(String text, Color color) {
    return Chip(
      label: Text(text),
      backgroundColor: color,
      labelStyle: TextStyle(color: const Color.fromARGB(255, 11, 11, 11)),
    );
  }

  Widget _buildDepartmentsTag(List<dynamic> departments) {
    return Wrap(
      children: departments.map((department) {
        return Chip(
          label: Text(department),
          backgroundColor: const Color.fromARGB(255, 229, 231, 234),
          labelStyle: TextStyle(color: const Color.fromARGB(255, 15, 14, 14)),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: userProfileData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData) {
            var user = snapshot.data!;
            var userName = user['firstName'] + ' ' + user['lastName'];
            var userEmail = user['emailAddress'];
            var userProfilePicture = user['profilePicture'];
            var userRating = user['userRating'] ?? 0;
            double userRatingDouble = userRating is int ? userRating.toDouble() : userRating;

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundImage: userProfilePicture != null && userProfilePicture.isNotEmpty
                        ? NetworkImage(userProfilePicture)
                        : null,
                    radius: 50,
                    child: userProfilePicture == null || userProfilePicture.isEmpty
                        ? Icon(Icons.person, size: 50)
                        : null,
                  ),
                  SizedBox(height: 16),
                  Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(userEmail, style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Rating: ${userRatingDouble.toDouble()}', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  Text('Active Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  FutureBuilder<List<DocumentSnapshot>>(
                    future: activeItems,
                    builder: (context, itemsSnapshot) {
                      if (itemsSnapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (itemsSnapshot.hasError) {
                        return Center(child: Text('Error: ${itemsSnapshot.error}'));
                      }

                      if (itemsSnapshot.hasData && itemsSnapshot.data!.isEmpty) {
                        return Center(child: Text('No active items'));
                      }

                      var items = itemsSnapshot.data!;
                      return Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            var item = items[index];
                            return GestureDetector(
                              onTap: () {
                                // Item'a tıklandığında detailed_item_screen.dart sayfasına yönlendir
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailedItemScreen(itemId: item.id),
                                  ),
                                );
                              },
                              child: Card(
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
                                            '₺${item['price'].toDouble()}',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          if (item['category'] == 'Rent')
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8.0),
                                              child: Text(
                                                item['paymentPlan'] ?? '',
                                                style: TextStyle(color: Colors.green),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          _buildTag(item['category'], Colors.green),
                                          _buildTag(item['condition'], const Color.fromARGB(255, 154, 197, 147)),
                                          if (item['departments'] is List) 
                                            _buildDepartmentsTag(item['departments']),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return Center(child: Text('No data available'));
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 59, 137, 62),
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(FontAwesomeIcons.shop), label: 'Items'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
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