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
    required String password,
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
          password: password,
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
    return User(
      userID: map['userID'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      emailAddress: map['emailAddress'],
      password: map['password'],
      isAdmin: map['isAdmin'],
      accountStatus: map['accountStatus'],
      profilePicture: map['profilePicture'],
      userRating: (map['userRating'] as num).toDouble(),
      favoriteItems: List<String>.from(map['favoriteItems'] ?? []),
    );
  }
}
