//bu değerlerin nullable olması ile burda mı ilgilenelim yoksa ui'da error handling ile mi?
class Item {
  final String title;
  final String description;
  final String category;
  final double price;
  final String condition;
  final String photo;
  final List<String> additionalPhotos;
  final List<String> departments;
  final int favoriteCount;
  final String itemType;
  final String paymentPlan;
  final String itemStatus; //string olması uygun mu yoksa int mi olmalı?
  final String itemOwnerId; 

  Item({
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.condition,
    required this.photo,
    required this.additionalPhotos,
    required this.departments,
    required this.favoriteCount,
    required this.itemType,
    required this.paymentPlan,
    required this.itemStatus,
    required this.itemOwnerId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      condition: json['condition'] as String,
      photo: json['photo'] as String,
      additionalPhotos: List<String>.from(json['additionalPhotos'] ?? []),
      departments: List<String>.from(json['departments'] ?? []),
      favoriteCount: json['favoriteCount'] as int? ?? 0,
      itemType: json['itemType'] as String,
      paymentPlan: json['paymentPlan'] as String,
      itemStatus: json['itemStatus'] as String,
      itemOwnerId: json['itemOwnerId'] as String,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'condition': condition,
      'photo': photo,
      'additionalPhotos': additionalPhotos,
      'departments': departments,
      'favoriteCount': favoriteCount,
      'itemType': itemType,
      'paymentPlan': paymentPlan,
      'itemStatus': itemStatus,
      'itemOwnerId': itemOwnerId,
    };
  }
}