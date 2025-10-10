// shop_search_page.dart - SIMPLIFIED AND ROBUST VERSION
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'location_service.dart';
import 'google_places_service.dart';
import 'enhanced_store_details_page.dart';

class ShopSearchPage extends StatefulWidget {
  const ShopSearchPage({super.key});

  @override
  State<ShopSearchPage> createState() => _ShopSearchPageState();
}

class _ShopSearchPageState extends State<ShopSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  List<ConstructionStore> _stores = [];
  bool _isLoading = false;
  Position? _currentPosition;
  String _statusMessage = ''; // User-facing status message
  String _sortBy = 'distance'; // 'distance' or 'rating'

  @override
  void initState() {
    super.initState();
    // DO NOT auto-request anything - wait for user to tap button
    print('🚀 Shop search page initialized - waiting for user action');
  }

  // --- Main Logic: Request Permission and Get Fresh Location ---
  // Helper method to detect simulator location
  bool _isSimulatorLocation(Position position) {
    // Common iOS Simulator default coordinates
    const double sfLat = 37.785834;
    const double sfLng = -122.406417;
    const double tolerance = 0.001; // Very small tolerance for exact match
    
    return (position.latitude - sfLat).abs() < tolerance && 
           (position.longitude - sfLng).abs() < tolerance;
  }

  Future<void> _getUserLocationAndSearch() async {
    setState(() {
      _isLoading = true;
      _stores = [];
      _currentPosition = null; // Clear any previous location
      _statusMessage = 'Requesting location permission...';
    });

    try {
      print('🔐 STEP 1: User tapped "Use My Location" - requesting permission...');
      
      // 1. Request permission using your service
      bool hasPermission = await LocationService.requestLocationPermission();
      
      if (!hasPermission) {
        print('❌ STEP 2: Permission denied by user');
        setState(() {
          _statusMessage = 'Location permission is required to find nearby stores.\n\nPlease allow location access or try "Set Location Manually" below.';
          _isLoading = false;
        });
        return;
      }

      print('✅ STEP 2: Permission granted! Getting FRESH location...');
      
      // 2. If permission is granted, get a FRESH location directly
      setState(() => _statusMessage = 'Permission granted! Getting your current location...');
      
      // Use Geolocator directly to get the most current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Balance between accuracy and speed
        timeLimit: Duration(seconds: 15), // Reasonable timeout
      );
      
      print('✅ STEP 3: Fresh location obtained - ${position.latitude}, ${position.longitude}');
      
      // Check if this is a simulator location
      bool isSimulatorLocation = _isSimulatorLocation(position);
      
      // Handle simulator vs real device locations
      if (isSimulatorLocation) {
        print('⚠️ STEP 4: Default simulator location detected - trying to get real location');
        
        // Try to get user's real location through IP geolocation as fallback
        Position? realLocation = await _tryGetRealLocationViaIP();
        
        if (realLocation != null) {
          print('✅ SUCCESS: Got real location via IP: ${realLocation.latitude}, ${realLocation.longitude}');
          setState(() {
            _currentPosition = realLocation;
            _statusMessage = 'Found your approximate location!\nSearching for nearby stores...';
          });
          await _searchNearbyStores();
        } else {
          // Fallback: Guide user to set location manually
          setState(() {
            _currentPosition = null;
            _statusMessage = '📱 iOS Simulator Detected\n\n🌍 To find stores near you:\n1. Use "Set Location Manually" below\n2. Enter your city/address\n\nOr set custom location in Simulator:\nDevice → Location → Custom Location';
            _isLoading = false;
          });
        }
      } else {
        // Real GPS coordinates - proceed with confidence
        print('🎯 STEP 4: Real location detected');
        setState(() {
          _currentPosition = position;
          _statusMessage = 'Location found: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}\nSearching for stores...';
        });
        await _searchNearbyStores();
      }

    } catch (e) {
      print('❌ Error in location flow: $e');
      setState(() {
        _statusMessage = 'Error: Could not get your location.\n\nTry:\n• Check location settings\n• Use "Set Location Manually" below';
        _isLoading = false;
      });
    }
  }

  // --- IP Geolocation Fallback ---
  Future<Position?> _tryGetRealLocationViaIP() async {
    try {
      print('🌐 Attempting to get real location via IP geolocation...');
      
      // Use a free IP geolocation service
      final response = await http.get(
        Uri.parse('http://ip-api.com/json/'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = convert.jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          double lat = data['lat'].toDouble();
          double lon = data['lon'].toDouble();
          String city = data['city'] ?? 'Unknown';
          String country = data['country'] ?? 'Unknown';
          
          print('✅ IP Geolocation success: $city, $country ($lat, $lon)');
          
          // Create a Position object with the IP-based coordinates
          return Position(
            latitude: lat,
            longitude: lon,
            timestamp: DateTime.now(),
            accuracy: 1000.0, // Lower accuracy for IP-based location
            altitude: 0.0,
            heading: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
            altitudeAccuracy: 0.0,
            headingAccuracy: 0.0,
          );
        }
      }
      
      print('❌ IP Geolocation failed: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Error getting IP location: $e');
      return null;
    }
  }

  // --- API Call Logic ---
  Future<void> _searchNearbyStores() async {
    if (_currentPosition == null) return;
    
    String query = _searchController.text.trim().isEmpty 
                   ? "construction supply store" 
                   : _searchController.text.trim();

    setState(() {
      _statusMessage = "Searching for '$query' near your location...";
    });

    try {
      print('🔍 STEP 4: Calling backend API for stores near ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      
      List<ConstructionStore> stores = await GooglePlacesService.searchNearbyStores(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        query: query,
      );

      print('✅ STEP 5: Found ${stores.length} stores from backend');

      setState(() {
        _stores = stores;
        // Apply current sort preference
        _sortStores(_sortBy);
        _isLoading = false;
        if (stores.isEmpty) {
          _statusMessage = "No '$query' stores found in your area.\n\nTry a different search term or location.";
        } else {
          _statusMessage = "Found ${stores.length} stores near you";
        }
      });
    } catch (e) {
      print('❌ Error searching for stores: $e');
      setState(() {
        _statusMessage = 'Error searching for stores: $e\n\nCheck if backend server is running.';
        _isLoading = false;
      });
    }
  }

  // --- Manual Location Setting ---
  void _showManualLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Your Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a city:'),
            const SizedBox(height: 16),
            
            // Quick city buttons
            Wrap(
              spacing: 8,
              children: [
                _buildCityButton('Coimbatore', 11.0168, 76.9558),
                _buildCityButton('Bangalore', 12.9716, 77.5946),
                _buildCityButton('Mumbai', 19.0760, 72.8777),
                _buildCityButton('Delhi', 28.7041, 77.1025),
                _buildCityButton('Chennai', 13.0827, 80.2707),
                _buildCityButton('Hyderabad', 17.3850, 78.4867),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildCityButton(String city, double lat, double lng) {
    return ElevatedButton(
      onPressed: () {
        _setManualLocation(lat, lng, city);
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      child: Text(city, style: const TextStyle(fontSize: 12)),
    );
  }

  void _setManualLocation(double lat, double lng, String cityName) {
    print('📍 MANUAL: User set location to $cityName ($lat, $lng)');
    setState(() {
      _currentPosition = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
      _isLoading = true;
      _statusMessage = 'Location set to $cityName. Searching for stores...';
    });
    
    // Immediately search for stores at this location
    _searchNearbyStores();
  }

  // --- Helper Methods ---
  Future<void> _openGoogleMaps(ConstructionStore store) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _callStore(String? phoneNumber) async {
    if (phoneNumber != null) {
      final url = 'tel:$phoneNumber';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  // --- Sorting ---
  void _sortStores(String sortBy) {
    _sortBy = sortBy;
    if (sortBy == 'distance') {
      _stores.sort((a, b) => a.distance.compareTo(b.distance));
    } else if (sortBy == 'rating') {
      _stores.sort((a, b) => b.rating.compareTo(a.rating)); // Higher rating first
    }
  }
  
  void _applySortAndRefresh(String sortBy) {
    setState(() {
      _sortStores(sortBy);
    });
  }

  // --- Navigation ---
  void _showStoreDetails(ConstructionStore store) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedStoreDetailsPage(store: store),
      ),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Construction Stores'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // If we DON'T have a location yet, show the permission request view
          if (_currentPosition == null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on, color: Colors.orange, size: 60),
                      const SizedBox(height: 16),
                      const Text(
                        'Find Construction Stores Near You',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Grant location permission to see construction supply stores, hardware stores, and building materials shops in your area.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      
                      if (_isLoading) ...[
                        const CircularProgressIndicator(color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(_statusMessage, 
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _getUserLocationAndSearch,
                            icon: const Icon(Icons.gps_fixed),
                            label: const Text('Use My Current Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _showManualLocationPicker,
                          icon: const Icon(Icons.edit_location, color: Colors.orange),
                          label: const Text('Set Location Manually', style: TextStyle(color: Colors.orange)),
                        ),
                      ],
                      
                      if (_statusMessage.isNotEmpty && !_isLoading) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(_statusMessage, 
                            style: TextStyle(color: Colors.red.shade700),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            )
          // If we DO have a location, show the search results view
          else
            Expanded(
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for specific stores or materials...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            if (_currentPosition != null) {
                              _searchNearbyStores();
                            }
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onSubmitted: (text) => _searchNearbyStores(),
                    ),
                  ),
                  
                  // Status/Location Info
                  if (_statusMessage.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_statusMessage, 
                              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                            ),
                          ),
                          IconButton(
                            onPressed: _showManualLocationPicker,
                            icon: Icon(Icons.edit_location, size: 16, color: Colors.orange.shade700),
                            tooltip: 'Change location',
                          ),
                        ],
                      ),
                    ),
                  
                  // Loading or Store List
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: Colors.orange),
                                SizedBox(height: 16),
                                Text('Loading stores...'),
                              ],
                            ),
                          )
                        : _stores.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.store, size: 64, color: Colors.grey),
                                    const SizedBox(height: 16),
                                    Text(_statusMessage.isNotEmpty ? _statusMessage : 'No stores found'),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _searchNearbyStores,
                                      child: const Text('Try Again'),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                children: [
                                  // Sort header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Found ${_stores.length} stores',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (_sortBy == 'distance') 
                                          const Text(
                                            ' • Sorted by distance',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        if (_sortBy == 'rating') 
                                          const Text(
                                            ' • Sorted by rating',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.amber,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        const Spacer(),
                                        const Text('Sort by: ', style: TextStyle(fontSize: 14)),
                                        DropdownButton<String>(
                                          value: _sortBy,
                                          underline: Container(),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'distance',
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.location_on, size: 16, color: Colors.blue),
                                                  SizedBox(width: 4),
                                                  Text('Distance'),
                                                ],
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: 'rating',
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.star, size: 16, color: Colors.amber),
                                                  SizedBox(width: 4),
                                                  Text('Rating'),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            if (value != null) {
                                              _applySortAndRefresh(value);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Store list
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _stores.length,
                                      padding: const EdgeInsets.all(16),
                                      itemBuilder: (context, index) {
                                  final store = _stores[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: ListTile(
                                      onTap: () => _showStoreDetails(store),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.orange,
                                        child: Text(
                                          store.name[0],
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(store.name),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(store.address),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.star, size: 16, color: Colors.amber),
                                              Text(' ${store.rating}'),
                                              const SizedBox(width: 16),
                                              Icon(Icons.location_on, size: 16, color: Colors.grey),
                                              Text(' ${_formatDistance(store.distance)}'),
                                              if (store.isOpen) ...[
                                                const SizedBox(width: 16),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Text('Open', 
                                                    style: TextStyle(color: Colors.white, fontSize: 10),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap for photos, reviews & details',
                                            style: TextStyle(
                                              color: Colors.blue[600],
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.directions, color: Colors.blue),
                                            onPressed: () => _openGoogleMaps(store),
                                            tooltip: 'Get Directions',
                                          ),
                                          if (store.phoneNumber != null)
                                            IconButton(
                                              icon: const Icon(Icons.phone, color: Colors.green),
                                              onPressed: () => _callStore(store.phoneNumber),
                                              tooltip: 'Call Store',
                                            ),
                                          IconButton(
                                            icon: const Icon(Icons.info, color: Colors.orange),
                                            onPressed: () => _showStoreDetails(store),
                                            tooltip: 'View Details',
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                                    ),
                                  ],
                                ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}