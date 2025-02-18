  import 'package:bees/views/screens/favorites_screen.dart';
  import 'package:bees/views/screens/home_screen.dart';
  import 'package:bees/views/screens/user_profile_screen.dart';
  import 'package:flutter/material.dart';
  import 'package:font_awesome_flutter/font_awesome_flutter.dart';
  import 'package:bees/views/screens/create_request_screen.dart';
  import 'package:bees/models/request_model.dart';
  import 'package:bees/controllers/request_controller.dart';
import 'package:bees/models/user_model.dart' as bees;

  class RequestsScreen extends StatefulWidget {
    const RequestsScreen({super.key});

    @override
    _RequestsScreenState createState() => _RequestsScreenState();
  }

  class _RequestsScreenState extends State<RequestsScreen> {
    int _selectedIndex = 1;
    TextEditingController _searchController = TextEditingController();
    final RequestController _requestController = RequestController();
  String _searchQuery = '';

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
            Expanded(child: _buildRequestList()),
          
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

    Widget _buildRequestList() {
    return StreamBuilder<List<Request>>(
      stream: _requestController.getRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No requests found"));
        }

        final requests = snapshot.data!
            .where((req) => req.requestContent.toLowerCase().contains(_searchQuery))
            .toList();

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(requests[index]);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(Request request) {
  return FutureBuilder<bees.User?>(
    future: _requestController.getUserByRequestID(request.requestID),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _loadingRequestCard(request); // Show a loading placeholder
      }

      if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
        return _errorRequestCard(request); // Show error UI
      }

      // User data retrieved successfully
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
                    backgroundColor: Color(0xFF3B893E),
                    backgroundImage: user.profilePicture.isNotEmpty
                        ? NetworkImage(user.profilePicture)
                        : null,
                    child: user.profilePicture.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "User: ${user.firstName} ${user.lastName}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                    "Status: ${request.requestStatus}",
                    style: TextStyle(
                      color: request.requestStatus == "Pending"
                          ? Colors.orange
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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