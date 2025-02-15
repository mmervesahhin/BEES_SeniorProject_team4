  import 'package:bees/views/screens/favorites_screen.dart';
  import 'package:bees/views/screens/home_screen.dart';
  import 'package:bees/views/screens/user_profile_screen.dart';
  import 'package:flutter/material.dart';
  import 'package:font_awesome_flutter/font_awesome_flutter.dart';
  import 'package:bees/views/screens/create_request_screen.dart';

  class RequestsScreen extends StatefulWidget {
    const RequestsScreen({super.key});

    @override
    _RequestsScreenState createState() => _RequestsScreenState();
  }

  class _RequestsScreenState extends State<RequestsScreen> {
    int _selectedIndex = 1;
    TextEditingController _searchController = TextEditingController();

    void _onItemTapped(int index) {
      if (index == _selectedIndex) return;
      switch (index) {
        case 0:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
          break;
        case 1:
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

    void _navigateToCreateRequest() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CreateRequestScreen()),
      );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 59, 137, 62),
          automaticallyImplyLeading: false,
          title: Text(
            'BEES',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.yellow,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.message),
              onPressed: () {},
              color: Colors.black,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),               
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: const Text('Requests - Body will be added later'),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToCreateRequest,
          backgroundColor: const Color.fromARGB(255, 59, 137, 62),
          child: Icon(Icons.add, color: Colors.white),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color.fromARGB(255, 59, 137, 62),
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
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
          ),
        ),
      );
    }
  }