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
                            leading: profileImageUrl != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(profileImageUrl),
                                  )
                                : const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(
                              reportedUserName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(
                                    text: 'Reported by: ',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                            trailing: ElevatedButton(
                              onPressed: () => _adminController.banUser(doc['userId']),
                              child: const Text('Ban'),
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
                            subtitle: const Text('Banned'),
                            trailing: ElevatedButton(
                              onPressed: () => _adminController.unbanUser(doc.id),
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
}
