import 'package:bees/controllers/blocked_user_controller.dart';
import 'package:bees/controllers/reported_user_controller.dart';
import 'package:bees/models/blocked_user_model.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/reported_user_model.dart';
import 'package:bees/models/user_model.dart';
import 'package:bees/views/screens/detailed_item_screen.dart';
import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';
import 'package:bees/views/screens/user_profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
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
  late Future<User> userProfileData;
  late Future<List<Item>> activeItems;
  final ReportedUserController _reportedUserController = ReportedUserController();
  final BlockedUserController _blockedUserController = BlockedUserController();
  String currentUserId = '';
  bool isBlocked = false;

Future<void> checkBlockedUsers() async {
  BlockedUserController blockedUserController = BlockedUserController();
  List<String> blockedUsers = await blockedUserController.getBlockedUsers(currentUserId);
  print("Blocked Users: $blockedUsers");
}
  @override
  void initState() {
    super.initState();
    userProfileData = fetchUserProfile();
    activeItems = fetchActiveItems();
    _getCurrentUserId();
    checkIfBlocked();
    checkBlockedUsers();
  }

   void _getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser  != null) {
      setState(() {
        currentUserId = currentUser.uid;  // currentUserId'yi alıyoruz
      });
    }
  }

  void checkIfBlocked() async {
  bool blocked = await _blockedUserController.isUserBlocked(widget.userId);
  setState(() {
    isBlocked = blocked;
  });
}

void toggleBlock() async {
  if (isBlocked) {
    await _blockedUserController.unblockUser(currentUserId,widget.userId);
  } else {
    await _blockedUserController.blockUser(currentUserId, widget.userId);
  }
  checkIfBlocked();

  setState(() {
    isBlocked = !isBlocked;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(isBlocked
          ? 'The blocked user will no longer be able to interact with you.'
          : 'You have unblocked this user.'),
      backgroundColor: isBlocked ? Colors.green : Colors.red,
      duration: Duration(seconds:4 ), // Mesajın gösterilme süresi
    ),
  );
}

  Future<User> fetchUserProfile() async {
    var doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (!doc.exists) {
      throw Exception("User not found");
    }
    return User.fromMap(doc.data()!);
  }

  Future<List<Item>> fetchActiveItems() async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('items')
        .where('itemOwnerId', isEqualTo: widget.userId)
        .where('itemStatus', isEqualTo: 'active')
        .get();
    return querySnapshot.docs.map((doc) => Item.fromJson(doc.data(), doc.id)).toList();
  }

  Widget _buildTag(String text, Color color) {
    return Chip(
      label: Text(text),
      backgroundColor: color,
      labelStyle: TextStyle(color: const Color.fromARGB(255, 11, 11, 11)),
    );
  }

List<Widget> _buildDepartmentsTag(List<dynamic> departments) {
  if (departments.isEmpty) return [];

  List<String> visibleDepartments = departments.map((e) => e.toString()).take(1).toList();

  if (departments.length > 1) {
    visibleDepartments.add('...');
  }

  return visibleDepartments
      .map((department) => _buildTag(department, const Color.fromARGB(255, 139, 197, 151)))
      .toList();
}
void _showReportDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String? selectedReason;
      String details = '';
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          return AlertDialog(
            title: Text(
              "Report User",
              style: TextStyle(color: Color.fromARGB(255, 17, 39, 18)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Please select a reason:",
                  style: TextStyle(color: Color.fromARGB(255, 29, 31, 29)),
                ),
                RadioListTile<String>(
                  title: Text(
                    "Harassment",
                    style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)),
                  ),
                  value: "Harassment",
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedReason = value;
                    });
                  },
                  activeColor: Color.fromARGB(255, 18, 73, 20),
                ),
                RadioListTile<String>(
                  title: Text(
                    "Suspicious or Fraudulent Behavior",
                    style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)),
                  ),
                  value: "Suspicious or Fraudulent Behavior",
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedReason = value;
                    });
                  },
                  activeColor: Color.fromARGB(255, 18, 73, 20),
                ),
                RadioListTile<String>(
                  title: Text(
                    "Inappropriate Profile Picture/Name/Surname",
                    style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)),
                  ),
                  value: "Inappropriate Profile Picture/Name/Surname",
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedReason = value;
                    });
                  },
                  activeColor: Color.fromARGB(255, 18, 73, 20),
                ),
                RadioListTile<String>(
                  title: Text(
                    "Hate Speech or Bullying",
                    style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)),
                  ),
                  value: "Hate Speech or Bullying",
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedReason = value;
                    });
                  },
                  activeColor: Color.fromARGB(255, 18, 73, 20),
                ),
                RadioListTile<String>(
                  title: Text(
                    "Violent Behavior",
                    style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)),
                  ),
                  value: "Violent Behavior",
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedReason = value;
                    });
                  },
                  activeColor: Color.fromARGB(255, 18, 73, 20),
                ),
                RadioListTile<String>(
                  title: Text(
                    "Other",
                    style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)),
                  ),
                  value: "Other",
                  groupValue: selectedReason,
                  onChanged: (value) {
                    setDialogState(() {
                      selectedReason = value;
                    });
                  },
                  activeColor: Color.fromARGB(255, 18, 73, 20),
                ),
                if (selectedReason == 'Other')
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Please describe your complaint",
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color.fromARGB(255, 18, 73, 20)),
                      ),
                    ),
                    onChanged: (text) {
                      setDialogState(() {
                        details = text;
                      });
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)),
                ),
              ),
              TextButton(
                onPressed: () async {
                  if (selectedReason == null || (selectedReason == 'Other' && details.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a reason and provide details if necessary')),
                    );
                    return;
                  }

                  var report = ReportedUser(
                    reportReason: selectedReason!,
                    complaintDetails: selectedReason == 'Other' ? details : '',
                    reportedBy: currentUserId,  // Bu kısmı oturum açan kullanıcının ID'si ile değiştirebilirsiniz
                    complaintID: DateTime.now().millisecondsSinceEpoch,  // Rapor için benzersiz ID
                    userId: widget.userId,
                  );

                  try {
                    // Raporu Firestore'a gönder
                    await _reportedUserController.addReport(report);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report submitted successfully')));
                    Navigator.of(context).pop();  // Pop-up'ı kapat
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to report user: $e')));
                  }
                },
                child: Text(
                  "Submit",
                  style: TextStyle(color: Color.fromARGB(255, 18, 73, 20)),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Profile', style: TextStyle(color: Colors.black)),
      backgroundColor: const Color.fromARGB(255, 248, 250, 248),
      elevation: 1,
      iconTheme: IconThemeData(color: Colors.black),
    ),
    body: FutureBuilder<User>(
      future: userProfileData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.hasData) {
          User user = snapshot.data!;
          String userName = '${user.firstName} ${user.lastName}';
          String userEmail = user.emailAddress;
          String userProfilePicture = user.profilePicture;
          double userRatingDouble = user.userRating;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: EdgeInsets.only(bottom: 16),
                  color: Color.fromARGB(255, 197, 227, 197),
                  child: Container(
                    width: double.infinity, // 💥 sayfa genişliği kadar genişlet
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundImage: userProfilePicture.isNotEmpty
                              ? NetworkImage(userProfilePicture)
                              : null,
                          radius: 40,
                          child: userProfilePicture.isEmpty ? Icon(Icons.person, size: 40) : null,
                        ),
                        SizedBox(height: 12),
                        Text(userName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text(userEmail, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        SizedBox(height: 6),
                        Text('Rating: ${userRatingDouble.toDouble()}', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                Text("Active Items", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Divider(),
                FutureBuilder<List<Item>>(
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
                                  builder: (context) => DetailedItemScreen(itemId: item.itemId!),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    item.photoUrl ?? 'https://via.placeholder.com/80', // Eğer null ise varsayılan resim kullan
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  item.title,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          '₺${item.price.toDouble()}',
                                          style: TextStyle(fontSize: 20),
                                        ),
                                        if (item.category == 'Rent')
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8.0),
                                            child: Text(
                                              item.paymentPlan ?? '',
                                              style: TextStyle(color: Colors.green),
                                            ),
                                          ),
                                      ],
                                    ),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            _buildTag(item.category, Colors.green),
                                            _buildTag(item.condition, const Color.fromARGB(255, 154, 197, 147)),
                                            if (item.departments is List)
                                              ..._buildDepartmentsTag(item.departments),
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
                // Aktif öğelerden sonra buton ekliyoruz
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showReportDialog,
                          icon: Icon(Icons.report, color: Colors.red),
                          label: Text("Report", style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: toggleBlock,
                          icon: Icon(
                            isBlocked ? Icons.lock_open : Icons.block,
                            color: isBlocked ? Colors.green : Colors.red,
                          ),
                          label: Text(
                            isBlocked ? "Unblock" : "Block",
                            style: TextStyle(color: isBlocked ? Colors.green : Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isBlocked ? Colors.green : Colors.red),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
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
