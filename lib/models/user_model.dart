import 'package:cloud_firestore/cloud_firestore.dart';
import 'actor_model.dart';

class User extends Actor {
  String profilePicture;
  double userRating;
  List<String> favoriteItems;

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

  // Firestore'a kaydetmek için nesneyi Map'e çevirir
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'profilePicture': profilePicture,
      'userRating': userRating,
      'favoriteItems': favoriteItems,
    });
    return map;
  }

  // Firestore'dan gelen veriyi User nesnesine çevirir
  static User fromMap(Map<String, dynamic> map) {
  print("🛠 Converting Firestore data to User model...");
  print("🔍 Raw Firestore data: $map");

  // Check if any required field is missing
  if (!map.containsKey('userID') || map['userID'] == null) {
    throw Exception("❌ Firestore data missing 'userID' field");
  }
  if (!map.containsKey('firstName') || map['firstName'] == null) {
    throw Exception("❌ Firestore data missing 'firstName' field");
  }
  if (!map.containsKey('lastName') || map['lastName'] == null) {
    throw Exception("❌ Firestore data missing 'lastName' field");
  }
  if (!map.containsKey('emailAddress') || map['emailAddress'] == null) {
    throw Exception("❌ Firestore data missing 'emailAddress' field");
  }

  return User(
    userID: map['userID'] ?? "",
    firstName: map['firstName'] ?? "Unknown",
    lastName: map['lastName'] ?? "User",
    emailAddress: map['emailAddress'] ?? "",
    hashedPassword: map['hashedPassword'] ?? "",  // ✅ Safe null handling
    isAdmin: map['isAdmin'] ?? false,
    accountStatus: map['accountStatus'] ?? "Inactive",
    profilePicture: map['profilePicture'] ?? "https://example.com/default.jpg",
    userRating: (map['userRating'] as num?)?.toDouble() ?? 0.0,
    favoriteItems: List<String>.from(map['favoriteItems'] ?? []),
  );
}

}
