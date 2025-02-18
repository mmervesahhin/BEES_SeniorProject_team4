import 'package:cloud_firestore/cloud_firestore.dart';

abstract class Actor {
  String userID;
  String firstName;
  String lastName;
  String emailAddress;
  String password;
  bool isAdmin;
  String accountStatus;

  Actor({
    required this.userID,
    required this.firstName,
    required this.lastName,
    required this.emailAddress,
    required this.password,
    required this.isAdmin,
    required this.accountStatus,
  });

  // Firestore'a kaydetmek için nesneyi Map'e çevirir
  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'firstName': firstName,
      'lastName': lastName,
      'emailAddress': emailAddress,
      'password': password,
      'isAdmin': isAdmin,
      'accountStatus': accountStatus,
    };
  }
}
