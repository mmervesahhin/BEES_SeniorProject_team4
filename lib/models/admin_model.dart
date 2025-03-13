import 'actor_model.dart';

class Admin extends Actor {

  Admin({
    required String userID,
    required String firstName,
    required String lastName,
    required String emailAddress,
    required String hashedPassword,
    required String accountStatus,
  }) : super(
          userID: userID,
          firstName: firstName,
          lastName: lastName,
          emailAddress: emailAddress,
          hashedPassword: hashedPassword,
          isAdmin: true, // Admin olduğu için sabit true.
          accountStatus: accountStatus,
        );

  // Firestore'a kaydetmek için nesneyi Map'e çevirir
  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
    });
    return map;
  }

  // Firestore'dan gelen veriyi Admin nesnesine çevirir
  static Admin fromMap(Map<String, dynamic> map) {
    return Admin(
      userID: map['userID'] ?? "",
      firstName: map['firstName'] ?? "Unknown",
      lastName: map['lastName'] ?? "Admin",
      emailAddress: map['emailAddress'] ?? "",
      hashedPassword: map['hashedPassword'] ?? "",
      accountStatus: map['accountStatus'] ?? "Active",
    );
  }
}
