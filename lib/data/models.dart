// lib/data/models.dart
class Product {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  bool isFavorited;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.isFavorited = false,
  });
}

class ConstructionStore {
  final String id;
  final String name;
  final String location;
  final String imageUrl;
  final List<Product> products;

  ConstructionStore({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.products,
  });
}
