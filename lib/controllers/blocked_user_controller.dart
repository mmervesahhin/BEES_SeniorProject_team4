import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlockedUserController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcıyı engelleme işlemi
  Future<void> blockUser(String currentUserId, String userIdToBlock) async {
    try {
      // 'blocked_users' koleksiyonunda, currentUserId dokümanının olup olmadığını kontrol ediyoruz
      DocumentSnapshot currentUserDoc = await _firestore.collection('blocked_users').doc(currentUserId).get();

      if (!currentUserDoc.exists) {
        // Eğer currentUserId dokümanı yoksa, yeni bir doküman oluşturuyoruz
        await _firestore.collection('blocked_users').doc(currentUserId).set({
          'blocked_users': [],
        });
      }

      // 'blocked_users' koleksiyonuna engellenen kullanıcıyı ekliyoruz
      await _firestore.collection('blocked_users').doc(currentUserId).update({
        'blocked_users': FieldValue.arrayUnion([userIdToBlock]),
      });

      // Engellenen kullanıcıya kim tarafından engellendiğini de kaydediyoruz
      await _firestore.collection('blocked_users').doc(userIdToBlock).collection('blockers').doc(currentUserId).set({
         'blockedBy': currentUserId, // Engelleyen kişinin ID'si
         'blockedAt': Timestamp.now(), // Engellenme tarihi
         'blockedUserId': userIdToBlock, // Bloklanan kişinin ID'si
      });

      print("User blocked successfully.");
      await cleanUpFavoritesAfterBlock(currentUserId, userIdToBlock);

    } catch (e) {
      throw Exception("Failed to block user: $e");
    }
  }

  // Kullanıcının engellediği kullanıcıları alma işlemi
  Future<List<String>> getBlockedUsers(String currentUserId) async {
    try {
      // 'blocked_users' koleksiyonundan engellenen kullanıcıları alıyoruz
      DocumentSnapshot doc = await _firestore.collection('blocked_users').doc(currentUserId).get();
      if (doc.exists) {
        return List<String>.from(doc['blocked_users'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      throw Exception("Failed to get blocked users: $e");
    }
    
  }

  // Kullanıcıyı engellemekten vazgeçme (unblock) işlemi
  Future<void> unblockUser(String currentUserId, String blockedUserId) async {
    try {
      // blocked_users koleksiyonunda engellenen kullanıcıyı kaldırıyoruz
      await _firestore.collection('blocked_users').doc(currentUserId).update({
        'blocked_users': FieldValue.arrayRemove([blockedUserId]),
      });

      // Engellenen kullanıcının, bloklayan kullanıcıdan kaldırılması işlemi
      await _firestore.collection('blocked_users').doc(blockedUserId).collection('blockers').doc(currentUserId).delete();

      print("User unblocked successfully.");
    } catch (e) {
      print("Failed to unblock user: $e");
      throw Exception("Failed to unblock user.");
    }
  }

  // Kullanıcının engellenip engellenmediğini kontrol etme işlemi
  Future<bool> isUserBlocked(String blockedUserId) async {
    try {
      // Geçerli kullanıcının 'blocked_users' koleksiyonundaki engellenen kullanıcılar listesini kontrol ediyoruz
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('blocked_users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        List<dynamic> blockedUsers = userDoc['blocked_users'] ?? [];
        return blockedUsers.contains(blockedUserId);
      }
      return false;
    } catch (e) {
      print("Error checking blocked user: $e");
      return false;
    }
  }
Future<void> cleanUpFavoritesAfterBlock(String currentUserId, String userIdToBlock) async {
  print("🧹 cleanUpFavoritesAfterBlock() çalıştı (array tabanlı)");

  try {
    // 1️⃣ A'nın dokümanını çek
    DocumentSnapshot currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    List<dynamic> currentUserFavorites = currentUserDoc['favoriteItems'] ?? [];

    for (String itemId in currentUserFavorites) {
      final itemDoc = await _firestore.collection('items').doc(itemId).get();
      if (itemDoc.exists && itemDoc['itemOwnerId'] == userIdToBlock) {
        // Remove from array
        await _firestore.collection('users').doc(currentUserId).update({
          'favoriteItems': FieldValue.arrayRemove([itemId])
        });
        print("✅ $itemId silindi (A'nın array'inden)");
      }
    }

    // 2️⃣ B'nin dokümanını çek
    DocumentSnapshot blockedUserDoc = await _firestore.collection('users').doc(userIdToBlock).get();
    List<dynamic> blockedUserFavorites = blockedUserDoc['favoriteItems'] ?? [];

    for (String itemId in blockedUserFavorites) {
      final itemDoc = await _firestore.collection('items').doc(itemId).get();
      if (itemDoc.exists && itemDoc['itemOwnerId'] == currentUserId) {
        await _firestore.collection('users').doc(userIdToBlock).update({
          'favoriteItems': FieldValue.arrayRemove([itemId])
        });
        print("✅ $itemId silindi (B'nin array'inden)");
      }
    }

    print("🎉 Favori array temizliği tamamlandı!");
  } catch (e) {
    print("❌ Favori array temizliği hatası: $e");
  }
}
}