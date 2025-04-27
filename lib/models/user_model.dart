import 'package:cloud_firestore/cloud_firestore.dart';

import 'actor_model.dart';

class User extends Actor {
  String profilePicture;
  double userRating;
  List<String> favoriteItems;
  bool isBanned;
  DateTime? banEndDate;

  User({
    required String userID,
    required String firstName,
    required String lastName,
    required String emailAddress,
    required String hashedPassword,
    required bool isAdmin,
    required String accountStatus,
    required this.profilePicture,
    required this.userRating,
    List<String>? favoriteItems,
    this.isBanned = false,
    this.banEndDate,
  })  : favoriteItems = favoriteItems ?? [],
        super(
          userID: userID,
          firstName: firstName,
          lastName: lastName,
          emailAddress: emailAddress,
          hashedPassword: hashedPassword,
          isAdmin: isAdmin,
          accountStatus: accountStatus,
        );

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'profilePicture': profilePicture,
      'userRating': userRating,
      'favoriteItems': favoriteItems,
      'isBanned': isBanned,
      'banEndDate': banEndDate?.toIso8601String(),
    });
    return map;
  }

  static User fromMap(Map<String, dynamic> map) {
    print("🛠 Converting Firestore data to User model...");
    print("🔍 Raw Firestore data: $map");

    if (!map.containsKey('userID') || map['userID'] == null) {
      throw Exception("Firestore data missing 'userID' field");
    }
    if (!map.containsKey('firstName') || map['firstName'] == null) {
      throw Exception("Firestore data missing 'firstName' field");
    }
    if (!map.containsKey('lastName') || map['lastName'] == null) {
      throw Exception("Firestore data missing 'lastName' field");
    }
    if (!map.containsKey('emailAddress') || map['emailAddress'] == null) {
      throw Exception("Firestore data missing 'emailAddress' field");
    }

    return User(
      userID: map['userID'] ?? "",
      firstName: map['firstName'] ?? "Unknown",
      lastName: map['lastName'] ?? "User",
      emailAddress: map['emailAddress'] ?? "",
      hashedPassword: map['hashedPassword'] ?? "",
      isAdmin: map['isAdmin'] ?? false,
      accountStatus: map['accountStatus'] ?? "Inactive",
      profilePicture: map['profilePicture'] ?? "https://example.com/default.jpg",
      userRating: (map['userRating'] as num?)?.toDouble() ?? 0.0,
      favoriteItems: List<String>.from(map['favoriteItems'] ?? []),
      isBanned: map['isBanned'] ?? false,
      banEndDate: map['banEndDate'] != null
    ? (map['banEndDate'] as Timestamp).toDate()
    : null,
    );
  }
}