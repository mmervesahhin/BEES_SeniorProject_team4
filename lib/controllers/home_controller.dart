import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeController {
  // The reference to the 'items' collection in Firestore
  final CollectionReference<Map<String, dynamic>> _itemsCollection =
      FirebaseFirestore.instance.collection('items');

  // This method returns a Stream of QuerySnapshots, filtered by the provided parameters
  Stream<QuerySnapshot<Map<String, dynamic>>> getItems({
    double? minPrice,
    double? maxPrice,
    String? category,
    List<String>? departments,
    String? condition,
  }) {
    // Start with the basic collection reference
    Query<Map<String, dynamic>> query = _itemsCollection;

    // Apply filters conditionally, ensuring that null values are handled
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

    // Return the stream of results (QuerySnapshot)
    return query.snapshots();
  }

  String getImageUrl(String photo) {
    return photo;
  }

  String getCategory(String category) {
    return category;
  }

  List<String> getDepartments(List<dynamic> departments) {
    return List<String>.from(departments);
  }

  Future<void> updateFavoriteCount(String itemId, bool isFavorited) async {
    DocumentReference<Map<String, dynamic>> itemDoc =
        _itemsCollection.doc(itemId);

    await itemDoc.update({
      'favoriteCount': FieldValue.increment(isFavorited ? 1 : -1),
    });
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
    if (filters['minPrice'] != null && filters['maxPrice'] != null) {
      priceValid = price >= filters['minPrice']! && price <= filters['maxPrice']!;
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
}