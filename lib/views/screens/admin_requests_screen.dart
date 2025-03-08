import 'package:bees/controllers/admin_controller.dart';
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/controllers/request_controller.dart';

import 'package:bees/models/user_model.dart' as bees;

  class AdminRequestsScreen extends StatefulWidget {
    const AdminRequestsScreen({super.key});

    @override
    _AdminRequestsScreenState createState() => _AdminRequestsScreenState();
  }

  class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
    int _selectedIndex = 1;
    TextEditingController _searchController = TextEditingController();
    final RequestController _requestController = RequestController();
    final currentUser = FirebaseAuth.instance.currentUser;
  
  String _searchQuery = '';
   final AdminController _controller = AdminController();

    void _onItemTapped(int index) {
      if (index == _selectedIndex) return;
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

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 59, 137, 62),
          automaticallyImplyLeading: false, // Geri butonunu kaldırır
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'BEES ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                TextSpan(
                  text: 'admin',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.yellow,
                  ),
                ),
              ],
            ),
          ),
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
                      onChanged: (value) {
                      setState(() {
                        _searchQuery = value; // Arama terimi değiştiğinde güncelle
                      });
                    },
                    ),
                  ),               
                ],
              ),
            ),
            Expanded(child: _buildRequestList()),
          
          ],
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
                icon: Icon(Icons.report),
                label: 'Reports',
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
          ),
        ),
      );

      
    }

Widget _buildRequestList() {
  return StreamBuilder<List<Request>>(
    stream: _requestController.getRequests(currentUser!.uid),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(child: Text("No requests found"));
      }

      String searchQueryLower = _searchQuery.toLowerCase(); // Küçük harfe çevir

      List<Request> filteredRequests = snapshot.data!.where((req) {
        String contentLower = req.requestContent.toLowerCase();
        return contentLower.contains(searchQueryLower); // Kısmi eşleşme
      }).toList();

      // Sonuçları alaka düzeyine göre sırala (daha yakın eşleşmeler önce gelir)
      filteredRequests.sort((a, b) {
        int relevanceA = _calculateRelevance(a.requestContent, searchQueryLower);
        int relevanceB = _calculateRelevance(b.requestContent, searchQueryLower);
        return relevanceB.compareTo(relevanceA); // Büyükten küçüğe sıralama
      });

      return ListView.builder(
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(filteredRequests[index]);
        },
      );
    },
  );
}
int _calculateRelevance(String text, String query) {
  text = text.toLowerCase();
  if (text.startsWith(query)) return 3; // En alakalı (başlangıçta eşleşme)
  if (text.contains(query)) return 2; // Kısmi eşleşme
  return 1; // Daha az alakalı
}


Widget _buildRequestCard(Request request) {
  return FutureBuilder<bees.User?>(
    future: _requestController.getUserByRequestID(request.requestID),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _loadingRequestCard(request); 
      }

      if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
        return _errorRequestCard(request); 
      }

      bees.User user = snapshot.data!;

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF3B893E),
                    backgroundImage: user.profilePicture.isNotEmpty
                        ? NetworkImage(user.profilePicture)
                        : null,
                    child: user.profilePicture.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${user.firstName} ${user.lastName}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onPressed: () {
                      _controller.showRequestRemoveOptions(context, request);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.requestContent,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(request.creationDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _loadingRequestCard(Request request) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: Colors.white,
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF3B893E),
            child: CircularProgressIndicator(),
          ),
          const SizedBox(width: 8),
          const Text(
            "Loading user...",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
  Widget _errorRequestCard(Request request) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: Colors.white,
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF3B893E),
            child: Icon(Icons.error, color: Colors.red),
          ),
          const SizedBox(width: 8),
          const Text(
            "User not found",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ],
      ),
    ),
  );
}


  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
  }
  }