import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bees/views/screens/create_request_screen.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/controllers/request_controller.dart';
import 'package:bees/views/screens/message_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'message_list_screen.dart';
import 'package:bees/views/screens/others_user_profile_screen.dart';
import 'package:bees/controllers/reported_request_controller.dart';
import 'package:bees/models/reported_request_model.dart';



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
  String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";//block için ihtiyacım vardı


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

    void _navigateToProfile(String userId, BuildContext context) {  //kullanıcı isminden ya da profilinden o kişinin profiline yönlendirmeyi burda yapıyorum.
  if (userId == FirebaseAuth.instance.currentUser!.uid) {
    // Eğer kullanıcı kendi profiline bakıyorsa
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserProfileScreen()),
    );
  } else {
    // Eğer başka birinin profiline bakıyorsa
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OthersUserProfileScreen(userId: userId)),
    );
  }
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
          onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessageListScreen(),
          ),
        );
      },
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
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToCreateRequest,
          backgroundColor: const Color.fromARGB(255, 59, 137, 62),
          child: Icon(Icons.edit, color: Colors.white),
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
    stream: _requestController.getRequests(currentUserId),
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
        
        // Kullanıcı adı bilgisi için kullanıcıyı getir
        bees.User? user = _requestController.cachedUsers[req.requestOwnerID];

        // Kullanıcı adı ve soyadı üzerinden arama yap
        String userNameLower = user != null ? "${user.firstName} ${user.lastName}".toLowerCase() : "";

        return contentLower.contains(searchQueryLower) || userNameLower.contains(searchQueryLower); 
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
                  GestureDetector(  //profile yönlendirmek için bu kısmı aşağıdaki gibi güncelledim
                    onTap: () {
                      _navigateToProfile(user.userID, context);
                    },
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF3B893E),
                      backgroundImage: user.profilePicture.isNotEmpty
                          ? NetworkImage(user.profilePicture)
                          : null,
                      child: user.profilePicture.isEmpty
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _navigateToProfile(user.userID, context);
                      },
                      child: Text(
                        "${user.firstName} ${user.lastName}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, color: Colors.black),
                    onPressed: () {
                      _navigateToMessageScreen(request, "Request");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.black),
                    onPressed: () {
                      _showReportOptions(context, request);
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

void _showReportOptions(BuildContext context, Request request) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text("Inappropriate for BEES"),
              onTap: () {
                _reportRequest(request, "Inappropriate for BEES");
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel),
              title: const Text("Illegal request"),
              onTap: () {
                _reportRequest(request, "Illegal request");
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    },
  );
}

void _reportRequest(Request request, String reason) async {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    print("Error: User not logged in");
      print("Request ${request.requestID} reported for: $reason");

    return;
  }


  // Aynı request'in daha önce raporlanıp raporlanmadığını kontrol et
  bool alreadyReported = await ReportedRequestController().hasUserReportedRequest(request.requestID, userId);
  
  if (alreadyReported) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You have already reported this request.")),
    );
    return;
  }

  // Yeni rapor kaydet
  ReportedRequest reportedRequest = ReportedRequest(
    requestId: request.requestID,
    reportedBy: userId,
    reportReason: reason,
    reportDate: DateTime.now(),
  );

  await ReportedRequestController().reportRequest(reportedRequest);

  // Kullanıcıya bildirim göster
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Request reported successfully!")),
  );
}


// Mesaj ekranına yönlendirme fonksiyonu
void _navigateToMessageScreen(dynamic entity, String entityType) {
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    // Kullanıcı giriş yapmamışsa, bir hata mesajı gösterebilirsiniz
    print("User is not logged in");
    return;
  }
  String senderId = "";
  String receiverId = currentUser.uid;

  if (entityType == "Item") {
    senderId = entity.itemOwnerId;
  } else if (entityType == "Request") {
    senderId = entity.requestOwnerID;
  }
  if (senderId == receiverId) {
    // SnackBar ile hata mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You cannot send a message to yourself!")),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => MessageScreen(
        entity: entity,
        entityType: entityType,
        senderId: senderId,
        receiverId: receiverId,
      ),
    ),
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