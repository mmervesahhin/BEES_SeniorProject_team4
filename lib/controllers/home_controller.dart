import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeController {
  final CollectionReference<Map<String, dynamic>> _itemsCollection =
      FirebaseFirestore.instance.collection('items');

  final CollectionReference<Map<String, dynamic>> _usersCollection =
      FirebaseFirestore.instance.collection('users');

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

Stream<List<DocumentSnapshot<Map<String, dynamic>>>> getItems({ 
  double? minPrice,
  double? maxPrice,
  String? category,
  List<String>? departments,
  String? condition,
}) {
  Query<Map<String, dynamic>> query = firestore.collection('items');
  query = query.where('itemStatus', isEqualTo: 'active');

  if (minPrice != null) {
    query = query.where('price', isGreaterThanOrEqualTo: minPrice);
  }
  if (maxPrice != null) {
    query = query.where('price', isLessThanOrEqualTo: maxPrice);
  }
  if (category != null) {
    query = query.where('category', isEqualTo: category);
  }
  if (departments != null && departments.isNotEmpty) {
    query = query.where('departments', arrayContainsAny: departments);
  }
  if (condition != null) {
    query = query.where('condition', isEqualTo: condition);
  }

  return query.snapshots().asyncMap((snapshot) async {
    String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return snapshot.docs; // Eğer giriş yapılmamışsa, direkt tüm ürünleri göster
    }

    List<DocumentSnapshot<Map<String, dynamic>>> filteredDocs = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final itemOwnerId = data['itemOwnerId'];

      DocumentSnapshot blockerDoc = await firestore
          .collection('blocked_users')
          .doc(currentUserId)
          .collection('blockers')
          .doc(itemOwnerId)
          .get(); 

      DocumentSnapshot blockerDoc2 = await firestore
          .collection('blocked_users')
          .doc(itemOwnerId)
          .collection('blockers')
          .doc(currentUserId)
          .get();

      DocumentSnapshot userDoc = await firestore
          .collection('users')
          .doc(itemOwnerId)
          .get();

      if (!blockerDoc.exists && !blockerDoc2.exists && userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData['isBanned'] == false) {
          filteredDocs.add(doc);
        }
      }
    }

    return filteredDocs; // Sadece bloklanmamış ve yasaklı olmayan kullanıcıların ürünlerini döndür
  });
}


    // Return the filtered item
  String getImageUrl(String photo) {
    return photo;
  }

  String getCategory(String category) {
    return category;
  }

  List<String> getDepartments(List<dynamic> departments) {
    return List<String>.from(departments);
  }

  Future<void> updateFavoriteCount(String itemId, bool isFavorited, String userId) async {
    DocumentReference<Map<String, dynamic>> itemDoc = _itemsCollection.doc(itemId);
    DocumentReference<Map<String, dynamic>> userDoc = _usersCollection.doc(userId);
    final itemRef = FirebaseFirestore.instance.collection('items').doc(itemId);
  final itemSnapshot = await itemRef.get();
  if (!itemSnapshot.exists) return;

  WriteBatch batch = FirebaseFirestore.instance.batch();

  
  if (!itemSnapshot.exists) {
    throw Exception("Item does not exist!");
  }

  // Mevcut favori sayısını al
  int currentFavoriteCount = itemSnapshot['favoriteCount'] ?? 0;

  // Eğer isFavorited true ise, favori sayısını 1 artır
  // Eğer isFavorited false ise, favori sayısını 1 azalt fakat negatif olmasın
  int newFavoriteCount = isFavorited
      ? currentFavoriteCount + 1
      : (currentFavoriteCount > 0 ? currentFavoriteCount - 1 : 0);

  // Item favori sayısını güncelle
  batch.update(itemDoc, {
    'favoriteCount': newFavoriteCount,
  });

  // Kullanıcının favori öğelerini güncelle
  batch.update(userDoc, {
    'favoriteItems': isFavorited
        ? FieldValue.arrayUnion([itemId])
        : FieldValue.arrayRemove([itemId]),
  });

  final itemData = itemSnapshot.data()!;
  final ownerId = itemData['itemOwnerId'];

  if (isFavorited) {
    // Favoriye ekleme işlemi
    await FirebaseFirestore.instance.collection('favorites').doc('$userId\_$itemId').set({
      'userId': userId,
      'itemId': itemId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 🛎️ Bildirim gönder
    if (ownerId != userId) {
      await FirebaseFirestore.instance.collection('notifications').add({
        'receiverId': ownerId, // ✅ doğru alan adı
        'message': 'Your item is added to Favorites',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'message', // type eklemek iyi olur, ikon ve renk için
      });
    }
  } else {
    // Favoriden çıkarma
    await FirebaseFirestore.instance.collection('favorites').doc('$userId\_$itemId').delete();
    }

    await batch.commit();
  }


  Future<bool> fetchFavoriteStatus(String itemId) async {
    var itemDoc = await _itemsCollection.doc(itemId).get();
    if (itemDoc.exists) {
      return (itemDoc['favoriteCount'] ?? 0) > 0;
    }
    return false;
  }

  bool applyFilters(
    double price,
    String condition,
    String category,
    String itemType,
    List<dynamic> selectedDepartments,
    Map<String, dynamic> filters,
  ) {
    bool priceValid = true;

    if (filters['minPrice'] != null) {
      priceValid = priceValid && price >= filters['minPrice'];
    }

    if (filters['maxPrice'] != null) {
      priceValid = priceValid && price <= filters['maxPrice'];
    }

    bool departmentValid = true;
    if (filters['departments'] != null && filters['departments'].isNotEmpty) {
      departmentValid = selectedDepartments.any((dept) => filters['departments']!.contains(dept)) || filters['departments']!.contains('All Departments');
    }

    return priceValid &&
        (condition == filters['condition'] || filters['condition'] == 'All') &&
        (category == filters['category'] || filters['category'] == 'All') &&
        (itemType == filters['itemType'] || filters['itemType'] == 'All') &&
        departmentValid;
  }

  Future<List<DocumentSnapshot>> fetchFavorites() async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      var favoriteItemIds = List<String>.from(userDoc['favoriteItems'] ?? []);

      if (favoriteItemIds.isNotEmpty) {
        var snapshot = await FirebaseFirestore.instance
            .collection('items')
            .where('itemId', whereIn: favoriteItemIds)
            .get();
        return snapshot.docs;
      } else {
        return [];
      }
    } catch (e) {
      print('Favorileri çekerken hata oluştu: $e');
      return [];
    }
  }
}
