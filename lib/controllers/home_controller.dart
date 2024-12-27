// lib/controllers/home_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeController {
  // Veritabanındaki item'ları almak
  Stream<QuerySnapshot> getItems() {
    return FirebaseFirestore.instance.collection('items').snapshots();
  }

  // Favori sayısını güncelleme
  void updateFavoriteCount(String itemId, bool isFavorited) async {
    var itemDoc = FirebaseFirestore.instance.collection('items').doc(itemId);

    await itemDoc.update({
      'favoriteCount': FieldValue.increment(isFavorited ? 1 : -1),
    });
  }

  // Fotoğraf URL'sini almak
  String getImageUrl(List<dynamic>? photos) {
    if (photos != null && photos.isNotEmpty) {
      return photos[0].replaceFirst('gs://', 'https://firebasestorage.googleapis.com/v0/b/your-app-id.appspot.com/o/');
    }
    return '';
  }

  // Kategori bilgisini almak (kategori bir string olarak geliyor)
  String getCategory(String? category) {
    if (category != null && category.isNotEmpty) {
      return category;
    }
    return 'Uncategorized';
  }

  // Departman bilgisini almak
  String getDepartments(dynamic departments) {
    if (departments != null && departments is List && departments.isNotEmpty) {
      return departments.first.toString();
    }
    return 'No department';
  }

  // Kategori bilgisini almak (itemId'ye göre)
  Future<String> getCategoryById(String itemId) async {
    var itemDoc = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
    var itemData = itemDoc.data();
    return itemData?['category'] ?? 'Uncategorized';
  }

  // Fotoğraf URL'sini almak (itemId'ye göre)
  Future<String> getImageUrlById(String itemId) async {
    var itemDoc = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
    var itemData = itemDoc.data();
    if (itemData?['photos'] != null && itemData?['photos'].isNotEmpty) {
      return itemData?['photos'][0].replaceFirst('gs://', 'https://firebasestorage.googleapis.com/v0/b/your-app-id.appspot.com/o/');
    }
    return ''; // varsayılan boş URL
  }
}