class Item {
  final String title; // Başlık
  final String description; // Açıklama
  final String category; // Kategori (örneğin: Sale, Rent, Gift)
  final double price; // Fiyat
  final String condition; // Durum (örneğin: New, Used, Refurbished)

  Item({
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.condition,
  });

  // JSON'dan Item nesnesine dönüştürme
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      condition: json['condition'] as String,
    );
  }

  // Item nesnesini JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'condition': condition,
    };
  }
}
