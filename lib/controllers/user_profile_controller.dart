import 'dart:async';

import 'package:bees/models/user_profile_model.dart';
import 'package:bees/views/screens/item_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bees/models/item_model.dart';
import 'package:bees/models/request_model.dart';
import 'package:bees/views/screens/edit_item_screen.dart';
import 'package:bees/views/screens/auth/login_screen.dart';
import 'package:bees/views/screens/favorites_screen.dart';
import 'package:bees/views/screens/home_screen.dart';
import 'package:bees/views/screens/requests_screen.dart';


class UserProfileController {
  final UserProfileModel model = UserProfileModel();
  final ImagePicker _picker = ImagePicker();
  
  // Form controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController newEmailController = TextEditingController();
  
  // Form keys
  final formKey = GlobalKey<FormState>();
  final passwordFormKey = GlobalKey<FormState>();
  final emailFormKey = GlobalKey<FormState>();
  
  // State variables
  File? image;
  bool isEditing = false;
  bool showActiveItems = false;
  bool showRequests = false;
  String? currentProfilePictureUrl;
  int selectedIndex = 3;
  
  // Password visibility states
  bool currentPasswordVisible = false;
  bool newPasswordVisible = false;
  bool confirmPasswordVisible = false;
  
  // Initialize controller with user data
  Future<void> initializeUserData() async {
    User? user = model.currentUser;
    if (user != null) {
      Map<String, dynamic>? userData = await model.getUserData(user.uid);
      if (userData != null) {
        firstNameController.text = userData['firstName'] ?? '';
        lastNameController.text = userData['lastName'] ?? '';
        currentProfilePictureUrl = userData['profilePicture'];
      }
    }
  }
  
  // Dispose controllers
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    newEmailController.dispose();
  }
  
  // Pick image from gallery or camera
  Future<void> pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      if (await imageFile.length() <= 10 * 1024 * 1024) {
        image = imageFile;
      } else {
        return Future.error('Image size must be less than 10MB');
      }
    }
  }
  
  // Remove profile picture
  Future<bool> removeProfilePicture() async {
    User? user = model.currentUser;
    if (user == null) return false;
    
    bool success = await model.removeProfilePicture(currentProfilePictureUrl, user.uid);
    if (success) {
      image = null;
      currentProfilePictureUrl = "";
    }
    return success;
  }

  // Add these methods to the UserProfileController class

// Get blocked users
Future<List<Map<String, dynamic>>> getBlockedUsers() async {
  User? user = model.currentUser;
  if (user == null) return [];
  
  return await model.getBlockedUsers(user.uid);
}
final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// Unblock a user
 Future<bool> unblockUser(String currentUserId, String blockedUserId) async {
  try {
    await _firestore.collection('blocked_users').doc(currentUserId).update({
      'blocked_users': FieldValue.arrayRemove([blockedUserId]),
    });

    await _firestore.collection('blocked_users')
        .doc(blockedUserId)
        .collection('blockers')
        .doc(currentUserId)
        .delete();

    print("User unblocked successfully.");
    return true;
  } catch (e) {
    print("Failed to unblock user: $e");
    return false;
  }
}

  // Example method (replace with actual logic)
  Future<String> getUserName() async {
    // Simulate fetching user name
    await Future.delayed(const Duration(seconds: 1));
    return "John Doe";
  }

  // Add this method to the UserProfileController class

  // Delete user account
  Future<String?> deleteUserAccount(String password) async {
    User? user = model.currentUser;
    if (user == null) return "User not found";

    try {
      // Re-authenticate the user
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete the user account
      return await model.deleteUserAccount();
    } catch (e) {
      if (e.toString().contains('wrong-password')) {
        return "The password is incorrect";
      } else if (e.toString().contains('requires-recent-login')) {
        return "Please log out and log back in before trying again";
      }
      return "Error deleting account: ${e.toString()}";
    }
  }



  
  // Save profile changes
  Future<bool> saveProfile() async {
    User? user = model.currentUser;
    if (user == null) return false;
    
    if (!formKey.currentState!.validate()) return false;
    
    try {
      String? imageUrl;
      if (image != null) {
        imageUrl = await model.uploadProfileImage(image!, user.uid);
      }

      Map<String, dynamic> updatedData = {
        'firstName': firstNameController.text,
        'lastName': lastNameController.text,
      };

      if (imageUrl != null) {
        updatedData['profilePicture'] = imageUrl;
      } else if (currentProfilePictureUrl == null) {
        updatedData['profilePicture'] = FieldValue.delete();
      }

      return await model.updateUserProfile(user.uid, updatedData);
    } catch (e) {
      print('Error in saveProfile: $e');
      return false;
    }
  }
  
  // Change password
  Future<String?> changePassword() async {
    if (!passwordFormKey.currentState!.validate()) return "Validation failed";
    
    if (newPasswordController.text != confirmPasswordController.text) {
      return "New passwords do not match";
    }
    
    // Validate password strength
    RegExp passwordRegex = RegExp("^(?=.*[A-Z])(?=.*\\d)(?=.*[!\"#\$%&'()*+,-./:;<=>?@[\\]^_`{|}~]).{8,}\$");
    if (!passwordRegex.hasMatch(newPasswordController.text)) {
      return "Password must be at least 8 characters and include an uppercase letter, a number, and a special character";
    }
    
    return await model.changePassword(
      currentPasswordController.text, 
      newPasswordController.text
    );
  }

  // Timer for checking email verification
Timer? _emailVerificationTimer;

// Start periodic check for email verification
void startEmailVerificationCheck() {
  // Cancel any existing timer
  _emailVerificationTimer?.cancel();
  
  // Check immediately
  _checkEmailVerification();
  
  // Then check every 5 seconds
  _emailVerificationTimer = Timer.periodic(Duration(seconds: 5), (timer) {
    _checkEmailVerification();
  });
}

// Stop periodic check
void stopEmailVerificationCheck() {
  _emailVerificationTimer?.cancel();
  _emailVerificationTimer = null;
}

// Callback for when email is verified
Function? onEmailVerified;

// Check for email verification
Future<void> _checkEmailVerification() async {
  User? user = model.currentUser;
  if (user == null) return;
  
  bool updated = await model.checkAndUpdateEmailVerification(user.uid);
  if (updated) {
    // Email was updated, refresh the UI
    stopEmailVerificationCheck(); // Stop checking
    
    // Call the callback if it exists
    if (onEmailVerified != null) {
      onEmailVerified!();
    }
  }
}


  // Resend email verification
Future<void> resendEmailVerification(String email) async {
  User? user = model.currentUser;
  if (user == null) return;
  
  try {
    await user.verifyBeforeUpdateEmail(email);
  } catch (e) {
    print('Error resending verification: $e');
  }
}


  
  // Change email
  Future<String?> changeEmail() async {
    if (!emailFormKey.currentState!.validate()) return "Validation failed";
    
    // Validate Bilkent email format
    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@(?:ug\.)?bilkent\.edu\.tr$").hasMatch(newEmailController.text)) {
      return "Please enter a valid Bilkent email address";
    }
    
    return await model.changeEmail(
      currentPasswordController.text, 
      newEmailController.text
    );
  }
  
  // Sign out
  Future<bool> signOut() async {
    return await model.signOut();
  }

  // Add these methods to the UserProfileController class

// Get inactive items stream
Stream<QuerySnapshot> getInactiveItemsStream(String userId) {
  return model.getInactiveItems(userId);
}

// Get beesed items stream
Stream<QuerySnapshot> getBeesedItemsStream(String userId) {
  return model.getBeesedItems(userId);
}

// Restore an inactive item
Future<bool> restoreInactiveItem(String itemId) async {
  return await model.restoreInactiveItem(itemId);
}

// Navigate to item history screen
void navigateToItemHistory(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ItemHistoryScreen(),
    ),
  );
}
  
  // Navigate to different screens
  void navigateTo(BuildContext context, int index) {
    if (index == selectedIndex) return;
    
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
        break;
      case 1:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => RequestsScreen()));
        break;
      case 2:
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => FavoritesScreen()));
        break;
    }
  }
  
  // Navigate to login screen
  void navigateToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
  
  // Navigate to edit item screen
  void navigateToEditItemScreen(BuildContext context, Item item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditItemScreen(item: item),
      ),
    );
  }
  
  // Mark item as BEESED
  Future<bool> markItemAsBeesed(Item item) async {
    return await model.markItemAsBeesed(item);
  }
  
  // Mark item as inactive
  Future<bool> markItemAsInactive(Item item) async {
    return await model.markItemAsInactive(item);
  }
  
 // Mark request as solved
Future<bool> markRequestAsSolved(Request request) async {
  return await model.markRequestAsSolved(request);
}

// Delete request (mark as removed)
Future<bool> deleteRequest(String requestId) async {
  return await model.deleteRequest(requestId);
}

// Get active requests stream
Stream<QuerySnapshot> getRequestsStream(String userId) {
  return model.getUserRequests(userId);
}

// Get solved requests stream
Stream<QuerySnapshot> getSolvedRequestsStream(String userId) {
  return model.getUserSolvedRequests(userId);
}


// Update request content
Future<bool> updateRequestContent(String requestId, String newContent) async {
  return await model.updateRequestContent(requestId, newContent);
}

// Get active items stream
Stream<QuerySnapshot> getActiveItemsStream(String userId) {
  // Direct Firestore access approach
  return FirebaseFirestore.instance
      .collection('items')
      .where('itemOwnerId', isEqualTo: userId)
      .where('itemStatus', isEqualTo: 'active')
      .snapshots();

}
}