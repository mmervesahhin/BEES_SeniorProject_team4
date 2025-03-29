import 'package:bees/controllers/admin_controller.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/user_model.dart';
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_detailed_item_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AdminOthersUserProfileScreen extends StatefulWidget {
  final String userId;

  const AdminOthersUserProfileScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  _OthersUserProfileScreenState createState() =>
      _OthersUserProfileScreenState();
}

class _OthersUserProfileScreenState extends State<AdminOthersUserProfileScreen> {
  late Future<User> userProfileData;
  late Future<List<Item>> activeItems;

  String currentUserId = '';
  final AdminController _adminController = AdminController();
  String? _selectedBanReason;
  String? _selectedBanDuration;
  String _banExplanation = '';

  @override
  void initState() {
    super.initState();
    userProfileData = fetchUserProfile();
    activeItems = fetchActiveItems();
    _getCurrentUserId();
  }

  void _getCurrentUserId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        currentUserId = currentUser.uid; // currentUserId'yi alıyoruz
      });
    }
  }

  Future<User> fetchUserProfile() async {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
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
    return querySnapshot.docs
        .map((doc) => Item.fromJson(doc.data(), doc.id))
        .toList();
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
                      if (itemsSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (itemsSnapshot.hasError) {
                        return Center(
                            child: Text('Error: ${itemsSnapshot.error}'));
                      }

                      if (itemsSnapshot.hasData &&
                          itemsSnapshot.data!.isEmpty) {
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AdminDetailedItemScreen(
                                        itemId: item.itemId!),
                                  ),
                                );
                              },
                              child: Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.photoUrl ??
                                          'https://via.placeholder.com/80',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '₺${item.price.toDouble()}',
                                            style: TextStyle(fontSize: 20),
                                          ),
                                          if (item.category == 'Rent')
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(left: 8.0),
                                              child: Text(
                                                item.paymentPlan ?? '',
                                                style: TextStyle(
                                                    color: Colors.green),
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
                  // Tek buton: Ban/Unban dinamik olarak stream üzerinden kontrol ediliyor
                      Center(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _adminController.getBannedUsers(),
                          builder: (context, banSnapshot) {
                            bool isBanned = false;
                            if (banSnapshot.hasData) {
                              isBanned = banSnapshot.data!.docs.any((doc) {
                                return doc['userID'] == user.userID;
                              });
                            }

                            return Tooltip(
                              message: isBanned
                                  ? "Lift ban from user"
                                  : "Permanently/temporarily ban this user",
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  if (isBanned) {
                                    _showUnbanDialog(user.userID);
                                  } else {
                                    _showBanDialog(user.userID);
                                  }
                                },
                                icon: Icon(
                                  isBanned ? Icons.lock_open : Icons.block,
                                  color: isBanned ? Colors.green : Colors.red,
                                ),
                                label: Text(
                                  isBanned ? 'Unban User' : 'Ban User',
                                  style: TextStyle(
                                    color: isBanned ? Colors.green : Colors.red,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isBanned ? Colors.green : Colors.red,
                                  ),
                                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                  textStyle: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                ],
              ),
            );
          }
          return Center(child: Text('No data available'));
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color.fromARGB(255, 59, 137, 62),
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
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AdminHomeScreen(),
                ));
                break;
              case 1:
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AdminRequestsScreen(),
                ));
                break;
              case 2:
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => AdminReportsScreen(),
                ));
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
          },
        ),
      ),
    );
  }

  void _showUnbanDialog(String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unban User'),
          content: const Text('Are you sure you want to unban this user?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Proceed with the unban operation
                _adminController.unbanUser(userId);
                Navigator.of(context).pop(); // Close the dialog after unbanning
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Show the dialog for banning a user
  void _showBanDialog(String userId) {
    // Reset the state of the dialog by clearing previous selections
    setState(() {
      _selectedBanReason = null;
      _selectedBanDuration = null;
      _banExplanation = '';
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ban User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ban reason dropdown with no default selection
                  DropdownButton<String>(
                    value: _selectedBanReason,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBanReason = newValue;
                      });
                    },
                    hint: const Text('Select Ban Reason'),
                    items: <String>[
                      'Harassment',
                      'Suspicious or Fraudulent Behavior',
                      'Inappropriate Profile Picture',
                      'Name or Surname Issues',
                      'Hate Speech or Bullying',
                      'Violent Behavior',
                      'Other'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  if (_selectedBanReason == 'Other')
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _banExplanation = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Explanation (Required)',
                      ),
                      autofocus: true,
                    ),
                  // Ban duration dropdown with no default selection
                  DropdownButton<String>(
                    value: _selectedBanDuration,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBanDuration = newValue;
                      });
                    },
                    hint: const Text('Select Ban Duration'),
                    items: <String>[
                      'Permanent',
                      '7 days',
                      '10 days',
                      '15 days',
                      '30 days'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: (_selectedBanReason == null ||
                          _selectedBanDuration == null ||
                          (_selectedBanReason == 'Other' &&
                              _banExplanation.isEmpty))
                      ? null // Disable button if required fields are not filled
                      : () {
                          // Call the ban user method
                          _adminController.banUser(
                            userId: userId,
                            banReason: _selectedBanReason!,
                            explanation: _banExplanation,
                            banPeriod: _selectedBanDuration!,
                          );
                          Navigator.of(context).pop();
                        },
                  child: const Text('Ban'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
