import 'dart:io';

class Item {
  String? itemId;
  String itemOwnerId;
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
  String itemStatus;

  Item({
    this.itemId,
    required this.itemOwnerId,
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
    required this.itemStatus,
  });

  // Convert Item object to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemOwnerId': itemOwnerId,
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
      'itemStatus': itemStatus,
    };
  }

  // Convert Firestore document to Item object
  factory Item.fromJson(Map<String, dynamic> json, String documentId) {
    return Item(
      itemId: documentId,
      itemOwnerId: json['itemOwnerId'],
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
      itemStatus: json['itemStatus'] ?? 'available',
    );
  }
}
