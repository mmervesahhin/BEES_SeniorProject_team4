import 'package:bees/controllers/user_profile_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUsersScreen extends StatefulWidget {
  @override
  _BlockedUsersScreenState createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final UserProfileController _controller = UserProfileController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedUsers = [];
  
  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }
  
 // Update the _loadBlockedUsers method in the _BlockedUsersScreenState class

Future<void> _loadBlockedUsers() async {
  setState(() {
    _isLoading = true;
  });
  
  try {
    List<Map<String, dynamic>> blockedUsers = await _controller.getBlockedUsers();
    
    setState(() {
      _blockedUsers = blockedUsers;
      _isLoading = false;
    });
  } catch (e) {
    print('Error loading blocked users: $e');
    setState(() {
      _blockedUsers = [];
      _isLoading = false;
    });
    
    _showSnackBar('Error loading blocked users', isError: true);
  }
}

// Update the _unblockUser method to handle the specific structure
Future<void> _unblockUser(String blockedUserId, String userName) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Unblock User',
        style: TextStyle(
          color: _controller.model.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'Are you sure you want to unblock $userName? They will be able to see your content and interact with you again.',
        style: TextStyle(color: _controller.model.textColor),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: _controller.model.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Unblock'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_controller.model.primaryColor),
          ),
        ),
      );

      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Remove the blocked user from the current user's blocked list
      await FirebaseFirestore.instance
          .collection('blocked_users')
          .doc(currentUserId)
          .update({
        'blocked_users': FieldValue.arrayRemove([blockedUserId]),
      });

      // Remove the blocker entry from the blocked user's "blockers" collection
      await FirebaseFirestore.instance
          .collection('blocked_users')
          .doc(blockedUserId)
          .collection('blockers')
          .doc(currentUserId)
          .delete();

      // Close loading indicator
      Navigator.of(context, rootNavigator: true).pop();

      // Show success message
      _showSnackBar('User unblocked successfully');

      // Refresh blocked users list
      await _loadBlockedUsers();
    } catch (e) {
      // Close loading indicator if an error occurs
      Navigator.of(context, rootNavigator: true).pop();
      _showSnackBar('Error unblocking user: ${e.toString()}', isError: true);
    }
  }
}



// Add this method to the _BlockedUsersScreenState class

void _showSnackBar(String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: isError ? _controller.model.errorColor : _controller.model.primaryColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.all(16),
      elevation: 4,
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _controller.model.backgroundColor,
      appBar: AppBar(
        backgroundColor: _controller.model.primaryColor,
        elevation: 0,
        title: Text(
          'Blocked Users',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_controller.model.primaryColor),
              ),
            )
          : _blockedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.block,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "You haven't blocked any users",
                        style: TextStyle(
                          fontSize: 16,
                          color: _controller.model.lightTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "When you block someone, they won't be able to see your profile or interact with you",
                        style: TextStyle(
                          fontSize: 14,
                          color: _controller.model.lightTextColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _blockedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _blockedUsers[index];
                    final fullName = "${user['firstName']} ${user['lastName']}";
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: user['profilePicture'] != null && user['profilePicture'].isNotEmpty
                                  ? NetworkImage(user['profilePicture'])
                                  : null,
                              child: user['profilePicture'] == null || user['profilePicture'].isEmpty
                                  ? Icon(Icons.person, color: Colors.grey.shade600)
                                  : null,
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _controller.model.textColor,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    user['emailAddress'] ?? '',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _controller.model.lightTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _unblockUser(user['userId'], fullName),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _controller.model.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: Text('Unblock'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}