import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedUser {
  final String userId;
  final String blockedBy;
  final DateTime blockedAt;

  BlockedUser({
    required this.userId,
    required this.blockedBy,
    required this.blockedAt,
  });

  // Firestore'a kaydetmek için map fonksiyonu
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'blockedBy': blockedBy,
      'blockedAt': blockedAt,
    };
  }

  // Firestore'dan veri çekmek için map'ten objeye dönüşüm
  factory BlockedUser.fromMap(Map<String, dynamic> map) {
    return BlockedUser(
      userId: map['userId'],
      blockedBy: map['blockedBy'],
      blockedAt: (map['blockedAt'] as Timestamp).toDate(),
    );
  }
}
