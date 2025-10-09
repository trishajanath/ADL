// google_places_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class ConstructionStore {
  final String placeId;
  final String name;
  final String address;
  final double rating;
  final String? photoReference;
  final double latitude;
  final double longitude;
  final bool isOpen;
  final String? phoneNumber;
  final double distance;

  ConstructionStore({
    required this.placeId,
    required this.name,
    required this.address,
    required this.rating,
    this.photoReference,
    required this.latitude,
    required this.longitude,
    required this.isOpen,
    this.phoneNumber,
    required this.distance,
  });

  factory ConstructionStore.fromJson(Map<String, dynamic> json, double userLat, double userLng) {
    final location = json['geometry']['location'];
    final lat = location['lat'].toDouble();
    final lng = location['lng'].toDouble();
    
    final distance = Geolocator.distanceBetween(userLat, userLng, lat, lng);

    return ConstructionStore(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? 'Unknown Store',
      address: json['vicinity'] ?? json['formatted_address'] ?? 'Address not available',
      rating: (json['rating'] ?? 0.0).toDouble(),
      photoReference: json['photos'] != null && json['photos'].isNotEmpty 
          ? json['photos'][0]['photo_reference'] 
          : null,
      latitude: lat,
      longitude: lng,
      isOpen: json['opening_hours']?['open_now'] ?? false,
      phoneNumber: json['formatted_phone_number'],
      distance: distance,
    );
  }
}

class GooglePlacesService {
  // Backend API configuration - Using local network IP instead of localhost
  // so the mobile device/simulator can reach the backend server
  static const String _backendUrl = 'http://127.0.0.1:8000';

  // Mock data for testing when API key is not configured or simulator location
  static List<ConstructionStore> _getMockStores(double latitude, double longitude) {
    // Check if this is San Francisco simulator coordinates
    bool isSanFranciscoSimulator = (latitude - 37.7858).abs() < 0.01 && (longitude + 122.4064).abs() < 0.01;
    
    if (isSanFranciscoSimulator) {
      // Return Indian construction stores with realistic SF distances for simulation
      return [
        ConstructionStore(
          placeId: 'mock_sf_1',
          name: 'Buildmate Construction Supplies',
          address: 'Mission District, San Francisco (Simulated)',
          rating: 4.3,
          latitude: latitude + 0.005,
          longitude: longitude + 0.005,
          isOpen: true,
          phoneNumber: '+1 (415) 555-0123',
          distance: 800,
        ),
        ConstructionStore(
          placeId: 'mock_sf_2', 
          name: 'Golden Gate Hardware & Cement',
          address: 'Castro District, San Francisco (Simulated)',
          rating: 4.1,
          latitude: latitude + 0.008,
          longitude: longitude - 0.003,
          isOpen: true,
          phoneNumber: '+1 (415) 555-0124',
          distance: 1200,
        ),
        ConstructionStore(
          placeId: 'mock_sf_3',
          name: 'Bay Area Building Materials',
          address: 'SOMA, San Francisco (Simulated)',
          rating: 4.0,
          latitude: latitude - 0.003,
          longitude: longitude + 0.007,
          isOpen: false,
          phoneNumber: '+1 (415) 555-0125',
          distance: 950,
        ),
        ConstructionStore(
          placeId: 'mock_sf_4',
          name: 'Pacific Construction Supply Co',
          address: 'Richmond District, San Francisco (Simulated)',
          rating: 4.4,
          latitude: latitude + 0.012,
          longitude: longitude - 0.008,
          isOpen: true,
          phoneNumber: '+1 (415) 555-0126',
          distance: 1600,
        ),
        ConstructionStore(
          placeId: 'mock_sf_5',
          name: 'SF Pro Building Supplies',
          address: 'Sunset District, San Francisco (Simulated)',
          rating: 3.9,
          latitude: latitude - 0.008,
          longitude: longitude - 0.005,
          isOpen: true,
          phoneNumber: '+1 (415) 555-0127',
          distance: 1100,
        ),
      ];
    }
    
    // Default mock stores for other locations (like Bangalore)
    return [
      ConstructionStore(
        placeId: 'mock_1',
        name: 'Gaamadhenu Building Materials',
        address: 'Near Market Square, Local Area',
        rating: 4.2,
        latitude: latitude + 0.01,
        longitude: longitude + 0.01,
        isOpen: true,
        phoneNumber: '+91 9876543210',
        distance: 1200,
      ),
      ConstructionStore(
        placeId: 'mock_2', 
        name: 'Supreme Construction Supply',
        address: 'Industrial Area, Local Area',
        rating: 4.0,
        latitude: latitude + 0.02,
        longitude: longitude + 0.02,
        isOpen: true,
        phoneNumber: '+91 9876543211',
        distance: 2400,
      ),
      ConstructionStore(
        placeId: 'mock_3',
        name: 'Metro Hardware & Cement',
        address: 'Main Road, Local Area',
        rating: 3.8,
        latitude: latitude - 0.01,
        longitude: longitude - 0.01,
        isOpen: false,
        phoneNumber: '+91 9876543212',
        distance: 1800,
      ),
      ConstructionStore(
        placeId: 'mock_4',
        name: 'Royal Building Materials',
        address: 'Commercial Street, Local Area',
        rating: 4.5,
        latitude: latitude + 0.015,
        longitude: longitude - 0.015,
        isOpen: true,
        phoneNumber: '+91 9876543213',
        distance: 3200,
      ),
    ];
  }

  static Future<List<ConstructionStore>> searchNearbyStores({
    required double latitude,
    required double longitude,
    String query = 'construction supply store',
    int radius = 5000, // 5km radius
  }) async {
    try {
      print('� Searching via backend API...');
      
      // Call our backend API instead of Google Places directly
      final response = await http.post(
        Uri.parse('$_backendUrl/api/v1/nearby-stores'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': query,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['error'] != null) {
          print('❌ Backend API Error: ${data['error']}');
          return _getMockStores(latitude, longitude); // Fallback to mock data
        }
        
        final results = data['stores'] as List;
        print('✅ Found ${results.length} stores from backend API');

        List<ConstructionStore> stores = results.map((store) {
          double distance = Geolocator.distanceBetween(
            latitude, longitude, 
            store['latitude'].toDouble(), 
            store['longitude'].toDouble()
          );
          
          return ConstructionStore(
            placeId: store['place_id'] ?? '',
            name: store['name'] ?? 'Unknown Store',
            address: store['address'] ?? 'Address not available',
            rating: (store['rating'] ?? 0.0).toDouble(),
            latitude: store['latitude'].toDouble(),
            longitude: store['longitude'].toDouble(),
            isOpen: store['isOpen'] ?? false,
            phoneNumber: null, // Would need additional API call for phone
            distance: distance,
          );
        }).toList();

        // Sort by distance
        stores.sort((a, b) => a.distance.compareTo(b.distance));

        return stores;
      } else {
        print('❌ Backend HTTP Error: ${response.statusCode}');
        return _getMockStores(latitude, longitude); // Fallback to mock data
      }
    } catch (e) {
      print('❌ Error calling backend API: $e');
      return _getMockStores(latitude, longitude); // Fallback to mock data
    }
  }

  static Future<List<ConstructionStore>> searchStoresByText({
    required double latitude,
    required double longitude,
    required String searchText,
    int radius = 10000, // 10km radius for text search
  }) async {
    // Use the same backend API with the search text
    return searchNearbyStores(
      latitude: latitude,
      longitude: longitude,
      query: searchText,
      radius: radius,
    );
  }

  static String getPhotoUrl(String photoReference, {int maxWidth = 400}) {
    // For now, return a placeholder since we're using backend API
    return 'https://via.placeholder.com/${maxWidth}x300?text=Store+Photo';
  }

  static Future<Map<String, dynamic>?> getStoreDetails(String placeId) async {
    try {
      // Call backend API for store details
      final response = await http.get(
        Uri.parse('$_backendUrl/api/v1/store-details/$placeId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['details'];
      }
      return null;
    } catch (e) {
      print('Error getting store details: $e');
      return null;
    }
  }
}