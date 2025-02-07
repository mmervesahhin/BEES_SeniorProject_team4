import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class User {
  String userID;
  String firstName;
  String lastName;
  String emailAddress;
  String hashedPassword;
  String profilePicture;
  double userRating;
  bool isAdmin;
  String accountStatus;

  User({
    required this.userID,
    required this.firstName,
    required this.lastName,
    required this.emailAddress,
    required this.hashedPassword,
    required this.profilePicture,
    required this.userRating,
    required this.isAdmin,
    required this.accountStatus,
  });

  // Convert User object to a map for saving to Firestore
  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'firstName': firstName,
      'lastName': lastName,
      'emailAddress': emailAddress,
      'hashedPassword': hashedPassword,
      'profilePicture': profilePicture,
      'userRating': userRating,
      'isAdmin': isAdmin,
      'accountStatus': accountStatus,
    };
  }

  // Create User object from Firestore data (map)
  static User fromMap(Map<String, dynamic> map) {
    return User(
      userID: map['userID'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      emailAddress: map['emailAddress'],
      hashedPassword: map['hashedPassword'],
      profilePicture: map['profilePicture'],
      userRating: map['userRating'],
      isAdmin: map['isAdmin'],
      accountStatus: map['accountStatus'],
    );
  }
}
