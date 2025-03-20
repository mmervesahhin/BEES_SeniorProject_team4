import 'package:firebase_auth/firebase_auth.dart';
import 'package:bees/views/screens/admin_others_user_profile_screen.dart';
import 'package:bees/controllers/admin_controller.dart';
import 'package:bees/views/screens/admin_data_analysis_screen.dart';
import 'package:bees/views/screens/admin_home_screen.dart';
import 'package:bees/views/screens/admin_profile_screen.dart';
import 'package:bees/views/screens/admin_reports_screen.dart';
import 'package:bees/views/screens/admin_requests_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  _UserReportsScreenState createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  int _selectedIndex = 2;
  final AdminController _adminController = AdminController();
  final currentUser = FirebaseAuth.instance.currentUser;

  // Declare variables to hold the selected reason and ban duration
  String? _selectedBanReason;
  String? _selectedBanDuration;
  String _banExplanation = '';

  void _navigateToProfile(String userId) {
  if (userId == currentUser?.uid) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminProfileScreen()),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminOthersUserProfileScreen(userId: userId),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 137, 62),
        title: const Text(
          'User Reports',
          style: TextStyle(
            fontSize: 24,
            color: Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Reported Users',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder(
                stream: _adminController.getReportedUsers(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No reported users.'));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      return FutureBuilder(
                        future: Future.wait([_adminController.getUserInfo(doc['reportedBy']), _adminController.getUserInfo(doc['userId'])]),
                        builder: (context, AsyncSnapshot<List<Map<String, dynamic>?>> userSnapshots) {
                          if (userSnapshots.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          String reportedByName = '${userSnapshots.data?[0]?['firstName'] ?? 'Unknown Reporter'} ${userSnapshots.data?[0]?['lastName'] ?? ''}';
                          String reportedUserName = '${userSnapshots.data?[1]?['firstName'] ?? 'Unknown User'} ${userSnapshots.data?[1]?['lastName'] ?? ''}';
                          String? profileImageUrl = userSnapshots.data?[1]?['profilePicture'];
                          String? complaintDetails = doc['complaintDetails'];

                          return ListTile(
                            leading: GestureDetector(
                              onTap: () => _navigateToProfile(doc['userId']),
                              child: profileImageUrl != null
                                  ? CircleAvatar(backgroundImage: NetworkImage(profileImageUrl))
                                  : const CircleAvatar(child: Icon(Icons.person)),
                            ),
                            title: GestureDetector(
                              onTap: () => _navigateToProfile(doc['userId']),
                              child: Text(
                                reportedUserName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            subtitle: RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  const TextSpan(
                                    text: 'Reported by: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: reportedByName),
                                  const TextSpan(
                                    text: '\nReason: ',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: doc['reportReason'] ?? 'No reason provided'),
                                  if (complaintDetails != null && complaintDetails.isNotEmpty) ...[
                                    const TextSpan(
                                      text: '\nDetails: ',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(text: complaintDetails),
                                  ],
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () => _showBanDialog(doc['userId']),
                                  child: const Text('Ban'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _adminController.ignoreUserReport(doc['complaintID']),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const Divider(),
            const Text(
              'Banned Users',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: StreamBuilder(
                stream: _adminController.getBannedUsers(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No banned users.'));
                  }
                  return ListView(
                    children: snapshot.data!.docs.map((doc) {
                      return FutureBuilder(
                        future: _adminController.getUserInfo(doc.id),
                        builder: (context, AsyncSnapshot<Map<String, dynamic>?> userSnapshot) {
                          if (userSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          String userName = '${userSnapshot.data?['firstName'] ?? 'Unknown User'} ${userSnapshot.data?['lastName'] ?? ''}';
                          String? profileImageUrl = userSnapshot.data?['profilePicture'];

                          return ListTile(
                            leading: profileImageUrl != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(profileImageUrl),
                                  )
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(
                              userName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: RichText(
                              text: TextSpan(
                              style: DefaultTextStyle.of(context).style,
                                children: [
                                const TextSpan(
                                  text: 'Expiration: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: (userSnapshot.data?['banEndDate'] as Timestamp?)?.toDate().toString().substring(0, 16) ?? 'Permanent'),
                              ],
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _showUnbanDialog(doc.id), // Show the unban confirmation dialog
                              child: const Text('Unban'),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
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
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analysis'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminHomeScreen()));
        break;
      case 1:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminRequestsScreen()));
        break;
      case 2:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminReportsScreen()));
        break;
      case 3:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminDataAnalysisScreen()));
        break;
      case 4:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => AdminProfileScreen()));
        break;
    }
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
                        (_selectedBanReason == 'Other' && _banExplanation.isEmpty))
                    ? null  // Disable button if required fields are not filled
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