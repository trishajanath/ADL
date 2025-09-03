// lib/data/mock_data.dart
import 'models.dart';

class MockDataService {
  static final List<ConstructionStore> _stores = [
    ConstructionStore(
      id: 'store_01',
      name: 'BuildRight Hardware',
      location: 'Coimbatore, Tamil Nadu',
      imageUrl: 'https://storage.googleapis.com/gweb-uniblog-publish-prod/images/new-store-H.2e16d0ba.fill-1440x810.jpg',
      products: [
        Product(id: 'p01', name: 'Cement Bag (50kg)', price: 450.00, imageUrl: 'https://i.imgur.com/v42a19G.jpeg', isFavorited: true),
        Product(id: 'p02', name: 'TMT Steel Rods (1 ton)', price: 55000.00, imageUrl: 'https://i.imgur.com/sC3I4d4.jpeg'),
        Product(id: 'p03', name: 'River Sand (1 unit)', price: 4000.00, imageUrl: 'https://i.imgur.com/w1wz4g2.jpeg'),
      ],
    ),
    ConstructionStore(
      id: 'store_02',
      name: 'Supreme Builders Supply',
      location: 'Chennai, Tamil Nadu',
      imageUrl: 'https://i.imgur.com/m520xQ9.jpeg',
      products: [
        Product(id: 'p04', name: 'Premium Emulsion Paint (20L)', price: 3500.00, imageUrl: 'https://i.imgur.com/UpO2m5j.jpeg'),
        Product(id: 'p05', name: 'PVC Pipes (10ft)', price: 300.00, imageUrl: 'https://i.imgur.com/bT0Pz9S.jpeg', isFavorited: true),
      ],
    ),
    ConstructionStore(
      id: 'store_03',
      name: 'Kovai Construction Mart',
      location: 'Coimbatore, Tamil Nadu',
      imageUrl: 'https://i.imgur.com/kS5A51P.jpeg',
      products: [
        Product(id: 'p01a', name: 'Cement Bag (50kg)', price: 460.00, imageUrl: 'https://i.imgur.com/v42a19G.jpeg'),
        Product(id: 'p06', name: 'Waterproofing Chemical (5L)', price: 1200.00, imageUrl: 'https://i.imgur.com/lJgQ4xT.jpeg'),
      ],
    ),
    ConstructionStore(
      id: 'store_04',
      name: 'Madurai Building Materials',
      location: 'Madurai, Tamil Nadu',
      imageUrl: 'https://i.imgur.com/9vL8d3E.jpeg',
      products: [
        Product(id: 'p02a', name: 'TMT Steel Rods (1 ton)', price: 56500.00, imageUrl: 'https://i.imgur.com/sC3I4d4.jpeg'),
        Product(id: 'p05a', name: 'PVC Pipes (10ft)', price: 310.00, imageUrl: 'https://i.imgur.com/bT0Pz9S.jpeg'),
      ],
    ),
  ];

  static List<ConstructionStore> getStores() => _stores;

  static List<Product> getFavoritedProducts() {
    return _stores
        .expand((store) => store.products)
        .where((product) => product.isFavorited)
        .toList();
  }

  static void toggleFavoriteStatus(String productId) {
    for (var store in _stores) {
      for (var product in store.products) {
        if (product.id == productId) {
          product.isFavorited = !product.isFavorited;
          return;
        }
      }
    }
  }
}
