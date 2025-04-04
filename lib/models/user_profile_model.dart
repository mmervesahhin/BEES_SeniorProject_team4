import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/request_model.dart';

class UserProfileModel {
  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // User data
  User? get currentUser => _auth.currentUser;
  
  // Theme colors
  final Color primaryColor = Color.fromARGB(255, 59, 137, 62);
  final Color accentColor = Colors.yellow;
  final Color textColor = Color(0xFF2D3748);
  final Color lightTextColor = Color(0xFF718096);
  final Color backgroundColor = Color(0xFFF7FAFC);
  final Color cardColor = Colors.white;
  final Color errorColor = Color(0xFFE53E3E);
  
  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Add these methods to the UserProfileModel class

// Get user's inactive items
Stream<QuerySnapshot> getInactiveItems(String userId) {
  return _firestore
      .collection('items')
      .where('itemOwnerId', isEqualTo: userId)
      .where('itemStatus', isEqualTo: 'inactive')
      .orderBy('lastModifiedDate', descending: true)
      .snapshots();
}

// Get user's beesed items
Stream<QuerySnapshot> getBeesedItems(String userId) {
  return _firestore
      .collection('beesed_items')
      .where('itemOwnerId', isEqualTo: userId)
      .orderBy('beesedDate', descending: true)
      .snapshots();
}

// Restore an inactive item to active status
Future<bool> restoreInactiveItem(String itemId) async {
  try {
    await _firestore.collection('items').doc(itemId).update({
      'itemStatus': 'active',
      'lastModifiedDate': FieldValue.serverTimestamp(),
    });
    
    // Update the user's inactiveItems list if needed
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('items').doc(itemId).update({
      'itemStatus': 'inactive',
      });
    }
    
    return true;
  } catch (e) {
    print('Error restoring item: $e');
    return false;
  }
}


  // Delete user account
  Future<String?> deleteUserAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return "User not found";

      String uid = user.uid;

      // Delete user data from Firestore
      // 1. Get user's items and delete them
      QuerySnapshot itemsSnapshot = await _firestore
          .collection('items')
          .where('itemOwnerId', isEqualTo: uid)
          .get();

      for (var doc in itemsSnapshot.docs) {
        await _firestore.collection('items').doc(doc.id).delete();
      }

      // 2. Get user's requests and delete them
      QuerySnapshot requestsSnapshot = await _firestore
          .collection('requests')
          .where('requestOwnerID', isEqualTo: uid)
          .get();

      for (var doc in requestsSnapshot.docs) {
        await _firestore.collection('requests').doc(doc.id).delete();
      }

      // 3. Delete user's profile picture from storage if it exists
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        String? profilePicture = userData['profilePicture'];

        if (profilePicture != null && profilePicture.isNotEmpty) {
          try {
            Reference storageRef = _storage.refFromURL(profilePicture);
            await storageRef.delete();
          } catch (e) {
            print('Error deleting profile picture: $e');
          }
        }
      }

      // 4. Delete user document from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // 5. Delete user from blocked_users collection
      try {
        await _firestore.collection('blocked_users').doc(uid).delete();
      } catch (e) {
        print('Error deleting blocked users: $e');
      }

      // 6. Delete Firebase Auth user
      await user.delete();

      return null; // Success, no error message
    } catch (e) {
      print('Error deleting account: $e');
      return e.toString();
    }
  }
  
  // Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage(File image, String uid) async {
    try {
      Reference storageRef = _storage.ref().child('profile_pictures/$uid.jpg');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
  
  // Remove profile picture from Firebase Storage
  Future<bool> removeProfilePicture(String? currentProfilePictureUrl, String uid) async {
    try {
      // Delete from Firebase Storage
      if (currentProfilePictureUrl != null && currentProfilePictureUrl.isNotEmpty) {
        Reference storageRef = _storage.refFromURL(currentProfilePictureUrl);
        await storageRef.delete();
      }

      // Update Firestore with an empty string
      await _firestore.collection('users').doc(uid).update({
        'profilePicture': "",
      });

      return true;
    } catch (e) {
      print('Error removing profile picture: $e');
      return false;
    }
  }
  
  // Update user profile in Firestore
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  



// Get blocked users
Future<List<Map<String, dynamic>>> getBlockedUsers(String userId) async {
  try {
    // Get the blocked_users document for the current user
    DocumentSnapshot blockedDoc = await _firestore.collection('blocked_users').doc(userId).get();
    
    if (!blockedDoc.exists) {
      return [];
    }
    
    Map<String, dynamic> blockedData = blockedDoc.data() as Map<String, dynamic>;
    List<String> blockedUserIds = [];
    
    // Extract the blocked_users array
    if (blockedData.containsKey('blocked_users')) {
      blockedUserIds = List<String>.from(blockedData['blocked_users'] ?? []);
    }
    
    if (blockedUserIds.isEmpty) {
      return [];
    }
    
    // Fetch user details for each blocked user ID
    List<Map<String, dynamic>> blockedUsers = [];
    for (String blockedId in blockedUserIds) {
      DocumentSnapshot blockedUserDoc = await _firestore.collection('users').doc(blockedId).get();
      if (blockedUserDoc.exists) {
        Map<String, dynamic> blockedUserData = blockedUserDoc.data() as Map<String, dynamic>;
        blockedUsers.add({
          'userId': blockedId,
          'firstName': blockedUserData['firstName'] ?? '',
          'lastName': blockedUserData['lastName'] ?? '',
          'profilePicture': blockedUserData['profilePicture'],
          'emailAddress': blockedUserData['emailAddress'] ?? '',
        });
      }
    }
    
    return blockedUsers;
  } catch (e) {
    print('Error getting blocked users: $e');
    return [];
  }
}

// Unblock a user
Future<bool> unblockUser(String currentUserId, String userToUnblockId) async {
  try {
    // Get the current blocked_users document
    DocumentSnapshot blockedDoc = await _firestore.collection('blocked_users').doc(currentUserId).get();
    
    if (!blockedDoc.exists) {
      return false;
    }
    
    // Remove the user from the blocked_users array
    await _firestore.collection('blocked_users').doc(currentUserId).update({
      'blocked_users': FieldValue.arrayRemove([userToUnblockId]),
    });
    
    // Also update the user's local blocked users cache if it exists
    // This ensures the home page will immediately reflect the change
    await _firestore.collection('users').doc(currentUserId).update({
      'blockedUsersCache': FieldValue.arrayRemove([userToUnblockId]),
      'lastBlockedUsersUpdate': FieldValue.serverTimestamp(),
    });
    
    // Clear any cached item filters that might be excluding this user's items
    await _firestore.collection('users').doc(currentUserId).update({
      'itemFilterCache': FieldValue.delete(),
    });
    
    return true;
  } catch (e) {
    print('Error unblocking user: $e');
    return false;
  }
}
  
  // Change user password
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return "User not found";
      
      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      return null; // Success, no error message
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        return "The current password is incorrect";
      } else if (e.toString().contains('requires-recent-login')) {
        return "Please log out and log back in before trying again";
      }
      return "Error changing password: ${e.toString()}";
    }
  }
  
  // Change user email
Future<String?> changeEmail(String currentPassword, String newEmail) async {
  try {
    User? user = _auth.currentUser;
    if (user == null) return "User not found";
    
    // Re-authenticate the user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    
    // Send verification email to the new address
    await user.verifyBeforeUpdateEmail(newEmail);
    
    // Store the pending email in Firestore, but don't update the actual email yet
    await _firestore.collection('users').doc(user.uid).update({
      'pendingEmail': newEmail,
      'emailChangeRequestTime': FieldValue.serverTimestamp(),
    });
    
    return null; // Success, no error message
  } catch (e) {
    if (e.toString().contains('requires-recent-login')) {
      return "Please log out and log back in before trying again";
    } else if (e.toString().contains('invalid-email')) {
      return "The email address is not valid";
    } else if (e.toString().contains('email-already-in-use')) {
      return "This email is already in use by another account";
    }
    return "Error changing email: ${e.toString()}";
  }
}

// Check if email verification is complete and update email if verified
Future<bool> checkAndUpdateEmailVerification(String uid) async {
  try {
    User? user = _auth.currentUser;
    if (user == null) return false;
    
    // Reload user to get the latest email
    await user.reload();
    user = _auth.currentUser; // Get the refreshed user
    
    // Get the user document from Firestore
    DocumentSnapshot userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) return false;
    
    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
    String? pendingEmail = userData['pendingEmail'];
    
    // If there's a pending email and the current email matches it, the verification is complete
    if (pendingEmail != null && user!.email == pendingEmail) {
      // Update the email in Firestore and remove the pending email
      await _firestore.collection('users').doc(uid).update({
        'emailAddress': pendingEmail,
        'pendingEmail': FieldValue.delete(),
        'emailChangeRequestTime': FieldValue.delete(),
      });
      
      print('Email verification complete: Updated email to $pendingEmail');
      return true; // Email was updated
    }
    return false; // No update needed
  } catch (e) {
    print('Error checking email verification: $e');
    return false;
  }
}
  // Sign out user
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      print('Error signing out: $e');
      return false;
    }
  }
  
  // Get user's active items
  Stream<QuerySnapshot> getActiveItems(String userId) {
    return _firestore
        .collection('items')
        .where('itemOwnerId', isEqualTo: userId)
        .where('itemStatus', isEqualTo: 'active')
        .snapshots();
  }
  
 
  
  // Mark item as BEESED
  Future<bool> markItemAsBeesed(Item item) async {
    try {
      // Get the current item data from Firestore
      DocumentSnapshot itemDoc = await _firestore
          .collection('items')
          .doc(item.itemId)
          .get();

      if (!itemDoc.exists) {
        return false;
      }

      Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
      itemData['itemStatus'] = 'beesed';
      itemData['beesedDate'] = FieldValue.serverTimestamp();

      // Move the item to the beesed_items collection
      await _firestore.collection('beesed_items').add(itemData);

      // Delete the item from the items collection
      await _firestore.collection('items').doc(item.itemId).delete();

      // Update the user's activeItems list
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'activeItems': FieldValue.arrayRemove([item.itemId]),
        });
      }

      return true;
    } catch (e) {
      print('Error marking item as BEESED: $e');
      return false;
    }
  }
  
  // Mark item as inactive
  Future<bool> markItemAsInactive(Item item) async {
    try {
      await _firestore.collection('items').doc(item.itemId).update({
        'itemStatus': 'inactive',
        'lastModifiedDate': FieldValue.serverTimestamp(),
      });

      // Update the user's activeItems list if needed
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'inactiveItems': FieldValue.arrayUnion([item.itemId]),
        });
      }
      
      return true;
    } catch (e) {
      print('Error marking item as inactive: $e');
      return false;
    }
  }
  
// Mark request as solved (update status instead of deleting)
Future<bool> markRequestAsSolved(Request request) async {
  try {
    // Update the request status to "solved" instead of deleting it
    await _firestore.collection('requests').doc(request.requestID).update({
      'requestStatus': 'solved',
      'lastModifiedDate': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    print('Error marking request as solved: $e');
    return false;
  }
}

// Delete request (mark as removed instead of actually deleting)
Future<bool> deleteRequest(String requestId) async {
  try {
    // Update the request status to "removed" instead of deleting it
    await _firestore.collection('requests').doc(requestId).update({
      'requestStatus': 'removed',
      'lastModifiedDate': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    print('Error marking request as removed: $e');
    return false;
  }
}

// Get user's active requests (filter out solved and removed)
Stream<QuerySnapshot> getUserRequests(String userId) {
  return _firestore
      .collection('requests')
      .where('requestOwnerID', isEqualTo: userId)
      .where('requestStatus', isEqualTo: 'active') // Only show active requests
      .snapshots();
}

// Get user's solved requests
Stream<QuerySnapshot> getUserSolvedRequests(String userId) {
  return _firestore
      .collection('requests')
      .where('requestOwnerID', isEqualTo: userId)
      .where('requestStatus', isEqualTo: 'solved')
      .snapshots();
}

// Add this method to your UserProfileModel class

// Update request content
Future<bool> updateRequestContent(String requestId, String newContent) async {
  try {
    await _firestore.collection('requests').doc(requestId).update({
      'requestContent': newContent,
      'lastModifiedDate': FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    print('Error updating request content: $e');
    return false;
  }
}
}