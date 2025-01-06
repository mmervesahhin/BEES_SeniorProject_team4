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

  // This function returns the URL of the first image in the 'photos' field
  String getImageUrl(String photo) {
    // If 'photos' list is not empty, return the first image URL
    return photo;
  }

  // This function returns the category of the item (could be extended for more complex logic)
  String getCategory(String category) {
    // In the real app, you might want to process or map the category string
    return category;
  }

  // This function takes a list of departments and returns the same list as a list of strings
  List<String> getDepartments(List<dynamic> departments) {
    // Simply return the departments list as a list of strings
    return List<String>.from(departments);
  }


  // This method is used to update the favorite count for an item
  Future<void> updateFavoriteCount(String itemId, bool isFavorited) async {
    // Logic to update the favorite count in the Firestore document
    DocumentReference<Map<String, dynamic>> itemDoc =
        _itemsCollection.doc(itemId);

    // Increment or decrement the favorite count based on the isFavorited value
    await itemDoc.update({
      'favoriteCount': FieldValue.increment(isFavorited ? 1 : -1),
    });
  }
}