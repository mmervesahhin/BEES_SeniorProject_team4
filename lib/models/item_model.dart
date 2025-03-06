import 'dart:io';

class Item {
  String? id;
  String title;
  String description;
  String category;
  String condition;
  String itemType;
  List<String> departments;
  double price;
  String? paymentPlan;
  String? photoUrl;
  List<String>? additionalPhotos;
  int favoriteCount;

  Item({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.condition,
    required this.itemType,
    required this.departments,
    required this.price,
    this.paymentPlan,
    this.photoUrl,
    this.additionalPhotos,
    this.favoriteCount = 0,
  });

  // Convert Item object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'condition': condition,
      'itemType': itemType,
      'departments': departments,
      'price': price,
      'paymentPlan': paymentPlan,
      'photo': photoUrl,
      'additionalPhotos': additionalPhotos,
      'favoriteCount': favoriteCount,
    };
  }

  // Convert Firestore document to Item object
  factory Item.fromJson(Map<String, dynamic> json, String documentId) {
    return Item(
      id: documentId,
      title: json['title'],
      description: json['description'],
      category: json['category'],
      condition: json['condition'],
      itemType: json['itemType'],
      departments: List<String>.from(json['departments']),
      price: (json['price'] as num).toDouble(),
      paymentPlan: json['paymentPlan'],
      photoUrl: json['photo'],
      additionalPhotos: json['additionalPhotos'] != null
          ? List<String>.from(json['additionalPhotos'])
          : [],
      favoriteCount: json['favoriteCount'] ?? 0,
    );
  }
}
