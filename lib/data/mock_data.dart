// lib/data/mock_data.dart
import 'models.dart';

class MockDataService {
  static final List<ConstructionStore> _stores = [
    ConstructionStore(
      id: 'store_01',
      name: 'BuildRight Hardware',
      location: 'Coimbatore, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      products: [
        Product(
          id: 'p01',
          name: 'Cement Bag (50kg)',
          price: 450.00,
          imageUrl: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
          isFavorited: true,
        ),
        Product(
          id: 'p02',
          name: 'TMT Steel Rods (1 ton)',
          price: 55000.00,
          imageUrl: 'https://images.unsplash.com/photo-1597149738901-e9d21c55ae7e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
        Product(
          id: 'p03',
          name: 'River Sand (1 unit)',
          price: 4000.00,
          imageUrl: 'https://images.unsplash.com/photo-1583425432853-1c6c0bc24b66?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
      ],
    ),
    ConstructionStore(
      id: 'store_02',
      name: 'Supreme Builders Supply',
      location: 'Chennai, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      products: [
        Product(
          id: 'p04',
          name: 'Premium Emulsion Paint (20L)',
          price: 3500.00,
          imageUrl: 'https://images.unsplash.com/photo-1571942676906-2dd986f38081?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
        Product(
          id: 'p05',
          name: 'PVC Pipes (10ft)',
          price: 300.00,
          imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
          isFavorited: true,
        ),
      ],
    ),
    ConstructionStore(
      id: 'store_03',
      name: 'Kovai Construction Mart',
      location: 'Coimbatore, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      products: [
        Product(
          id: 'p01a',
          name: 'Cement Bag (50kg)',
          price: 460.00,
          imageUrl: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
        Product(
          id: 'p06',
          name: 'Waterproofing Chemical (5L)',
          price: 1200.00,
          imageUrl: 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
      ],
    ),
    ConstructionStore(
      id: 'store_04',
      name: 'Madurai Building Materials',
      location: 'Madurai, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      products: [
        Product(
          id: 'p02a',
          name: 'TMT Steel Rods (1 ton)',
          price: 56500.00,
          imageUrl: 'https://images.unsplash.com/photo-1597149738901-e9d21c55ae7e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
        Product(
          id: 'p05a',
          name: 'PVC Pipes (10ft)',
          price: 310.00,
          imageUrl: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
      ],
    ),
    ConstructionStore(
      id: 'store_05',
      name: 'Tirunelveli Construction Depot',
      location: 'Tirunelveli, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      products: [
        Product(
          id: 'p07',
          name: 'Red Bricks (1000 pieces)',
          price: 8000.00,
          imageUrl: 'https://images.unsplash.com/photo-1519985176271-adb1088fa94c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
        Product(
          id: 'p08',
          name: 'Concrete Blocks (500 pieces)',
          price: 12000.00,
          imageUrl: 'https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
          isFavorited: true,
        ),
        Product(
          id: 'p09',
          name: 'Roofing Tiles (100 sq ft)',
          price: 2500.00,
          imageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
      ],
    ),
    ConstructionStore(
      id: 'store_06',
      name: 'Salem Hardware Hub',
      location: 'Salem, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      products: [
        Product(
          id: 'p10',
          name: 'Electrical Wires (100m)',
          price: 1500.00,
          imageUrl: 'https://images.unsplash.com/photo-1594736797933-d0301ba2fe65?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
        Product(
          id: 'p11',
          name: 'Switch Boards (10 pieces)',
          price: 800.00,
          imageUrl: 'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
        Product(
          id: 'p12',
          name: 'LED Bulbs (20 pieces)',
          price: 1200.00,
          imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
          isFavorited: true,
        ),
      ],
    ),
    ConstructionStore(
      id: 'store_07',
      name: 'Erode Building Solutions',
      location: 'Erode, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1572981779307-38b8cabb2407?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      products: [
        Product(
          id: 'p13',
          name: 'Marble Tiles (50 sq ft)',
          price: 15000.00,
          imageUrl: 'https://images.unsplash.com/photo-1600298881974-6be191ceeda1?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
        Product(
          id: 'p14',
          name: 'Granite Slabs (20 sq ft)',
          price: 25000.00,
          imageUrl: 'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
        Product(
          id: 'p15',
          name: 'Ceramic Tiles (100 sq ft)',
          price: 8000.00,
          imageUrl: 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
      ],
    ),
    ConstructionStore(
      id: 'store_08',
      name: 'Trichy Construction Center',
      location: 'Trichy, Tamil Nadu',
      imageUrl: 'https://images.unsplash.com/photo-1497366216548-37526070297c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
      products: [
        Product(
          id: 'p16',
          name: 'Wooden Doors (2 pieces)',
          price: 18000.00,
          imageUrl: 'https://images.unsplash.com/photo-1595515106969-1ce29566ff1c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
        Product(
          id: 'p17',
          name: 'Window Frames (4 pieces)',
          price: 12000.00,
          imageUrl: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
          isFavorited: true,
        ),
        Product(
          id: 'p18',
          name: 'Hardware Fittings (Set)',
          price: 2500.00,
          imageUrl: 'https://images.unsplash.com/photo-1504307651254-35680f356dfd?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=80',
        ),
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