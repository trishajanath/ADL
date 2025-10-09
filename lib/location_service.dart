// location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<bool> requestLocationPermission() async {
    try {
      print('🔐 Starting location permission request...');
      
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('📡 Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      print('📋 Current permission status: $permission');

      // If already granted, return true immediately
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        print('✅ Location permission already granted');
        return true;
      }

      // Force request permission if not already granted
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.unableToDetermine) {
        print('🔄 Requesting location permission - permission dialog will appear...');
        
        // This triggers the iOS/Android permission dialog
        permission = await Geolocator.requestPermission();
        print('📋 Permission response from user: $permission');
      }
      
      // Handle different permission states
      if (permission == LocationPermission.denied) {
        print('❌ Location permission denied by user');
        return false;
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        return false;
      }

      bool isGranted = permission == LocationPermission.whileInUse || permission == LocationPermission.always;
      print(isGranted ? '✅ Location permission GRANTED by user' : '❌ Location permission NOT granted');
      
      return isGranted;
    } catch (e) {
      print('❌ Error requesting location permission: $e');
      return false;
    }
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      print('🌍 Starting location fetch...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }
      print('✅ Location services are enabled');

      // Check current permission status (don't request again here)
      LocationPermission permission = await Geolocator.checkPermission();
      print('📋 Current permission status: $permission');
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        print('❌ Location permission not granted (status: $permission)');
        return null;
      }

      print('📍 Getting current position with GPS...');
      
      // Try to get actual location first
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium, // Balanced accuracy vs speed
          timeLimit: Duration(seconds: 20), // Reasonable timeout
        );

        print('✅ Real GPS location found: ${position.latitude}, ${position.longitude}');
        print('📊 Accuracy: ${position.accuracy}m, Timestamp: ${position.timestamp}');
        return position;
        
      } catch (locationError) {
        print('⚠️ GPS timeout or error: $locationError');
        print('🔄 Trying last known location...');
        
        // Fallback to last known location
        try {
          Position? lastPosition = await Geolocator.getLastKnownPosition();
          if (lastPosition != null) {
            print('✅ Using last known location: ${lastPosition.latitude}, ${lastPosition.longitude}');
            return lastPosition;
          }
        } catch (e) {
          print('❌ No last known location available: $e');
        }
        
        throw locationError; // Re-throw original error
      }

    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}