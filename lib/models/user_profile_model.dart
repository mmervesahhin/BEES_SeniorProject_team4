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
      
      // Store the pending email in Firestore
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
  
  // Get user's requests
  Stream<QuerySnapshot> getUserRequests(String userId) {
    return _firestore
        .collection('requests')
        .where('requestOwnerID', isEqualTo: userId)
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
          'beesedItems': FieldValue.arrayUnion([item.itemId]),
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
  
  // Mark request as solved (delete it)
  Future<bool> markRequestAsSolved(Request request) async {
    try {
      await _firestore.collection('requests').doc(request.requestID).delete();
      return true;
    } catch (e) {
      print('Error marking request as solved: $e');
      return false;
    }
  }
  
  // Update request content
  Future<bool> updateRequestContent(String requestId, String newContent) async {
    try {
      await _firestore.collection('requests').doc(requestId).update({
        'requestContent': newContent,
        'lastModifiedDate': DateTime.now(),
      });
      return true;
    } catch (e) {
      print('Error updating request: $e');
      return false;
    }
  }
  
  // Delete request
  Future<bool> deleteRequest(String requestId) async {
    try {
      await _firestore.collection('requests').doc(requestId).delete();
      return true;
    } catch (e) {
      print('Error deleting request: $e');
      return false;
    }
  }
}