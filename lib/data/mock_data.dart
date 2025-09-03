// lib/data/mock_data.dart
import 'models.dart';

class MockDataService {
  static final List<ConstructionStore> _stores = [
    ConstructionStore(
      id: 'store_01',
      name: 'BuildRight Hardware',
      location: 'Coimbatore, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1581182800629-7d99595676a6?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      products: [
        Product(id: 'p01', name: 'Cement Bag (50kg)', price: 450.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80', isFavorited: true),
        Product(id: 'p02', name: 'TMT Steel Rods (1 ton)', price: 55000.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
        Product(id: 'p03', name: 'River Sand (1 unit)', price: 4000.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
      ],
    ),
    ConstructionStore(
      id: 'store_02',
      name: 'Supreme Builders Supply',
      location: 'Chennai, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1600858925935-3855021c1bb3?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      products: [
        Product(id: 'p04', name: 'Premium Emulsion Paint (20L)', price: 3500.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
        Product(id: 'p05', name: 'PVC Pipes (10ft)', price: 300.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80', isFavorited: true),
      ],
    ),
    ConstructionStore(
      id: 'store_03',
      name: 'Kovai Construction Mart',
      location: 'Coimbatore, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1593349389422-9a5a1f067d2?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      products: [
        Product(id: 'p01a', name: 'Cement Bag (50kg)', price: 460.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
        Product(id: 'p06', name: 'Waterproofing Chemical (5L)', price: 1200.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
      ],
    ),
    ConstructionStore(
      id: 'store_04',
      name: 'Madurai Building Materials',
      location: 'Madurai, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1516935633458-4931a7ae7243?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      products: [
        Product(id: 'p02a', name: 'TMT Steel Rods (1 ton)', price: 56500.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
        Product(id: 'p05a', name: 'PVC Pipes (10ft)', price: 310.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
      ],
    ),
    ConstructionStore(
      id: 'store_05',
      name: 'Tirunelveli Construction Depot',
      location: 'Tirunelveli, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      products: [
        Product(id: 'p07', name: 'Red Bricks (1000 pieces)', price: 8000.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
        Product(id: 'p08', name: 'Concrete Blocks (500 pieces)', price: 12000.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80', isFavorited: true),
        Product(id: 'p09', name: 'Roofing Tiles (100 sq ft)', price: 2500.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
      ],
    ),
    ConstructionStore(
      id: 'store_06',
      name: 'Salem Hardware Hub',
      location: 'Salem, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      products: [
        Product(id: 'p10', name: 'Electrical Wires (100m)', price: 1500.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
        Product(id: 'p11', name: 'Switch Boards (10 pieces)', price: 800.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
        Product(id: 'p12', name: 'LED Bulbs (20 pieces)', price: 1200.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80', isFavorited: true),
      ],
    ),
    ConstructionStore(
      id: 'store_07',
      name: 'Erode Building Solutions',
      location: 'Erode, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      products: [
        Product(id: 'p13', name: 'Marble Tiles (50 sq ft)', price: 15000.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
        Product(id: 'p14', name: 'Granite Slabs (20 sq ft)', price: 25000.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
        Product(id: 'p15', name: 'Ceramic Tiles (100 sq ft)', price: 8000.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
      ],
    ),
    ConstructionStore(
      id: 'store_08',
      name: 'Trichy Construction Center',
      location: 'Trichy, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1581094794329-c8112a89af12?ixlib=rb-4.0.3&auto=format&fit=crop&w=600&q=80',
      products: [
        Product(id: 'p16', name: 'Wooden Doors (2 pieces)', price: 18000.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
        Product(id: 'p17', name: 'Window Frames (4 pieces)', price: 12000.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80', isFavorited: true),
        Product(id: 'p18', name: 'Hardware Fittings (Set)', price: 2500.00, imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=300&q=80'),
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