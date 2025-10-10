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
  final String? website;
  final List<String>? openingHours;
  final int? priceLevel;
  final int? userRatingsTotal;
  final List<String>? types;
  final String? formattedAddress;
  final List<Map<String, dynamic>>? reviews;
  final List<String>? photos;
  final List<String> inferredProductCategories;

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
    this.website,
    this.openingHours,
    this.priceLevel,
    this.userRatingsTotal,
    this.types,
    this.formattedAddress,
    this.reviews,
    this.photos,
    required this.inferredProductCategories,
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
      website: json['website'],
      openingHours: json['opening_hours']?['weekday_text']?.cast<String>(),
      priceLevel: json['price_level'],
      userRatingsTotal: json['user_ratings_total'],
      types: json['types']?.cast<String>(),
      formattedAddress: json['formatted_address'],
      inferredProductCategories: (json['inferred_product_categories'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class GooglePlacesService {
  // Backend API configuration - Using local network IP instead of localhost
  // so the mobile device/simulator can reach the backend server
  static const String _backendUrl = 'http://127.0.0.1:8000';

  static Future<List<ConstructionStore>> searchNearbyStores({
    required double latitude,
    required double longitude,
    String query = 'construction supply store',
    int radius = 5000, // 5km radius
  }) async {
    try {
      print('🔍 Searching via backend API...');
      print('📍 User coordinates: $latitude, $longitude');
      
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
          return []; // Return empty list instead of mock data
        }
        
        final results = data['stores'] as List;
        print('✅ Found ${results.length} stores from backend API');

        List<ConstructionStore> stores = results.map((store) {
          double distance = Geolocator.distanceBetween(
            latitude, longitude, 
            store['latitude'].toDouble(), 
            store['longitude'].toDouble()
          );
          
          print('🏪 Store: ${store['name']} at ${store['latitude']}, ${store['longitude']} - Distance: ${(distance/1000).toStringAsFixed(1)}km');
          print('🏷️ Categories: ${store['inferred_product_categories']}');
          
          return ConstructionStore(
            placeId: store['place_id'] ?? '',
            name: store['name'] ?? 'Unknown Store',
            address: store['address'] ?? 'Address not available',
            rating: (store['rating'] ?? 0.0).toDouble(),
            latitude: store['latitude'].toDouble(),
            longitude: store['longitude'].toDouble(),
            isOpen: store['isOpen'] ?? false,
            phoneNumber: store['phone_number'], 
            distance: distance,
            website: store['website'],
            openingHours: store['opening_hours']?.cast<String>(),
            priceLevel: store['price_level'],
            userRatingsTotal: store['user_ratings_total'],
            types: store['types']?.cast<String>(),
            formattedAddress: store['formatted_address'],
            photoReference: store['photo_reference'],
            photos: store['photos']?.cast<String>(),
            reviews: store['reviews']?.cast<Map<String, dynamic>>(),
            inferredProductCategories: (store['inferred_product_categories'] as List<dynamic>?)?.cast<String>() ?? [],
          );
        }).toList();

        // Sort by distance
        stores.sort((a, b) => a.distance.compareTo(b.distance));

        return stores;
      } else {
        print('❌ Backend HTTP Error: ${response.statusCode}');
        return []; // Return empty list instead of mock data
      }
    } catch (e) {
      print('❌ Error calling backend API: $e');
      return []; // Return empty list instead of mock data
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
    // If we have a photo reference, try to get the actual photo via backend
    if (photoReference.isNotEmpty && !photoReference.startsWith('http')) {
      return '$_backendUrl/api/v1/store-photo/$photoReference?maxwidth=$maxWidth';
    }
    
    // If it's already a URL, return it directly
    if (photoReference.startsWith('http')) {
      return photoReference;
    }
    
    // Fallback to placeholder
    return 'https://via.placeholder.com/${maxWidth}x300/e3f2fd/6366f1?text=Construction+Store';
  }

  static Future<Map<String, dynamic>?> getStoreDetails(String placeId) async {
    try {
      print('🔍 Fetching detailed information for place_id: $placeId');
      
      // Call backend API for store details
      final response = await http.get(
        Uri.parse('$_backendUrl/api/v1/store-details/$placeId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['error'] != null) {
          print('❌ Backend API Error: ${data['error']}');
          return null;
        }
        
        print('✅ Retrieved detailed store information');
        return data['details'];
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting store details: $e');
      return null;
    }
  }
}