import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final User? firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Profile Page")),
        body: Center(child: Text("User not found.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Page"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return Center(child: Text("User data not found. Please complete your profile."));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: userData['profilePicture'] != null && userData['profilePicture'].isNotEmpty
                      ? NetworkImage(userData['profilePicture'])
                      : AssetImage("assets/default_avatar.png") as ImageProvider,
                ),
                SizedBox(height: 20),
                Text("Name: ${userData['firstName'] ?? 'Unknown'} ${userData['lastName'] ?? ''}", style: TextStyle(fontSize: 18)),
                Text("Email: ${userData['emailAddress'] ?? 'Unknown'}", style: TextStyle(fontSize: 18)),
                Text("Rating: ${(userData['userRating'] ?? 0).toString()}", style: TextStyle(fontSize: 18)),
                Text("Account Status: ${userData['accountStatus'] ?? 'Unknown'}", style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),
                Text("Favorite Items:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ...((userData['favoriteItems'] as List<dynamic>? ?? []).map((item) => Text(item, style: TextStyle(fontSize: 16)))).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}