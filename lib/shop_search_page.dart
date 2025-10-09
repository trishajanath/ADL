import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' as convert;
import 'dart:async'; // Import for Future
import 'location_service.dart';
import 'google_places_service.dart';

class ShopSearchPage extends StatefulWidget {
  const ShopSearchPage({super.key});

  @override
  State<ShopSearchPage> createState() => _ShopSearchPageState();
}

class _ShopSearchPageState extends State<ShopSearchPage> {
  // --- STATE VARIABLES ---
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  List<ConstructionStore> _stores = [];
  bool _isLoading = false;
  Position? _currentPosition;
  String _statusMessage = 'Tap the button to find stores near you.';

  /// This is the main function that handles the entire user flow.
  Future<void> _getUserLocationAndSearch() async {
    // --- STEP 1: RESET STATE AND START LOADING ---
    setState(() {
      _isLoading = true;
      _stores = [];
      _currentPosition = null; // Important: Clear any old position
      _statusMessage = 'Requesting location permission...';
    });
    print('=== 🎯 AUTOMATIC LOCATION FLOW STARTED ===');

    try {
      // --- STEP 2: REQUEST PERMISSION ---
      print('1️⃣ Requesting location permission...');
      bool hasPermission = await LocationService.requestLocationPermission();
      
      if (!hasPermission) {
        print('❌ Permission Denied by User.');
        setState(() {
          _statusMessage = 'Location permission is required to find nearby stores.';
          _isLoading = false;
        });
        return;
      }

      // --- STEP 3: GET PRECISE, FRESH LOCATION ---
      print('2️⃣ Permission granted! Getting your precise location...');
      setState(() => _statusMessage = 'Getting your precise location...');
      
      // Try multiple location methods for maximum accuracy
      Position position = await _getPreciseLocation();

      print('✅ SUCCESS! Fetched location: ${position.latitude}, ${position.longitude}');
      print('📊 Location details: accuracy=${position.accuracy}m, timestamp=${position.timestamp}');
      
      // Check if this looks like simulator coordinates
      bool isSimulator = _isSimulatorLocation(position);
      print(isSimulator ? '⚠️ SIMULATOR DETECTED: This is the default iOS Simulator location' : '🎯 REAL LOCATION: This appears to be actual GPS coordinates');
      
      // --- STEP 4: HANDLE REAL VS SIMULATOR LOCATION ---
      if (isSimulator) {
        print('🤖 SIMULATOR WORKAROUND: Will show SF stores but inform user');
        setState(() {
          _currentPosition = position;
          _statusMessage = '⚠️ iOS Simulator detected - showing San Francisco area stores.\nOn a real device, this will show stores near your actual location.';
        });
      } else {
        // Real GPS coordinates - proceed with full confidence
        setState(() {
          _currentPosition = position;
          _statusMessage = 'Found your location! Searching for nearby stores...';
        });
      }

      await _searchNearbyStores();

    } catch (e) {
      print('❌ FAILED to get location: $e');
      setState(() {
        _statusMessage = 'Could not access your location automatically.\nPlease ensure location services are enabled.';
        _isLoading = false;
      });
      
      // Fallback to manual location after a delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          _showManualLocationPicker();
        }
      });
    }
  }

  /// Get the most precise location possible
  Future<Position> _getPreciseLocation() async {
    try {
      // First try: High accuracy with longer timeout
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );
    } catch (e) {
      print('⚠️ Best accuracy failed, trying high accuracy: $e');
      try {
        // Second try: High accuracy with medium timeout
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 20),
        );
      } catch (e) {
        print('⚠️ High accuracy failed, trying medium accuracy: $e');
        // Final try: Medium accuracy
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 15),
        );
      }
    }
  }

  /// Helper to detect iOS Simulator default coordinates
  bool _isSimulatorLocation(Position position) {
    const double sfLat = 37.785834;
    const double sfLng = -122.406417;
    const double tolerance = 0.001;
    
    return (position.latitude - sfLat).abs() < tolerance && 
           (position.longitude - sfLng).abs() < tolerance;
  }

  /// This function calls your backend to get the list of stores.
  Future<void> _searchNearbyStores() async {
    if (_currentPosition == null) {
      print('❌ Search cancelled: current position is null.');
      return;
    }
    
    String query = _searchController.text.trim().isEmpty 
                   ? "construction supply store" 
                   : _searchController.text.trim();
    
    print('3️⃣ Calling backend to search for "$query" near ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');

    setState(() {
      _statusMessage = "Searching for '$query' near your location...";
    });

    try {
      List<ConstructionStore> stores = await GooglePlacesService.searchNearbyStores(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        query: query,
      );

      print('4️⃣ Backend returned ${stores.length} stores.');

      setState(() {
        _stores = stores;
        _isLoading = false;
        if (stores.isEmpty) {
          _statusMessage = "No '$query' stores found in your area.\n\nTry a different search term.";
        } else {
          _statusMessage = "Found ${stores.length} stores near you";
        }
      });
    } catch (e) {
      print('❌ FAILED to get stores from backend: $e');
      setState(() {
        _statusMessage = 'Error searching for stores: $e';
        _isLoading = false;
      });
    } finally {
      print('=== 🏁 LOCATION FLOW FINISHED ===');
    }
  }

  /// Geocode an address and search for nearby stores
  Future<void> _geocodeAndSearch(String address) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Finding location for: $address...';
    });

    try {
      print('🗺️ GEOCODING: Converting address "$address" to coordinates');
      
      // Use Google's Geocoding API via our backend
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/v1/geocode'),
        headers: {'Content-Type': 'application/json'},
        body: convert.jsonEncode({'address': address}),
      );

      if (response.statusCode == 200) {
        final data = convert.jsonDecode(response.body);
        if (data['success'] == true && data['location'] != null) {
          double lat = data['location']['latitude'];
          double lng = data['location']['longitude'];
          
          print('✅ GEOCODED: $address → $lat, $lng');
          
          setState(() {
            _currentPosition = Position(
              latitude: lat,
              longitude: lng,
              timestamp: DateTime.now(),
              accuracy: 5.0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
            _statusMessage = 'Found location: $address\nSearching for stores...';
          });

          await _searchNearbyStores();
        } else {
          setState(() {
            _statusMessage = 'Could not find location for: $address\nTry a more specific address.';
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Geocoding service unavailable');
      }
    } catch (e) {
      print('❌ GEOCODING FAILED: $e');
      setState(() {
        _statusMessage = 'Error finding location. Please try again or select a city.';
        _isLoading = false;
      });
    }
  }

  /// Show manual location picker for users who want to override GPS
  void _showManualLocationPicker() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to make a choice
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_city, color: Colors.orange),
            SizedBox(width: 8),
            Text('Set Your Location'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter your specific address to find the closest stores',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Address input field
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Enter your address',
                hintText: 'e.g., RS Puram, Coimbatore or MG Road, Bangalore',
                prefixIcon: Icon(Icons.home, color: Colors.orange),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange, width: 2),
                ),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showQuickCityPicker();
                    },
                    icon: Icon(Icons.location_city, size: 16),
                    label: Text('Quick Cities'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_addressController.text.trim().isNotEmpty) {
                        Navigator.pop(context);
                        _geocodeAndSearch(_addressController.text.trim());
                      }
                    },
                    icon: Icon(Icons.search, size: 16),
                    label: Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _statusMessage = 'Please enter your address to find nearby stores.';
                _isLoading = false;
              });
            },
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  void _showQuickCityPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quick City Selection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Select a city center (you can refine your address later):'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCityButton('🏭 Coimbatore', 11.0168, 76.9558, 'Tamil Nadu • Industrial Hub'),
                _buildCityButton('🌆 Bangalore', 12.9716, 77.5946, 'Karnataka • Tech City'),
                _buildCityButton('🏖️ Chennai', 13.0827, 80.2707, 'Tamil Nadu • Port City'),
                _buildCityButton('🏙️ Mumbai', 19.0760, 72.8777, 'Maharashtra • Financial Capital'),
                _buildCityButton('🏛️ Delhi', 28.7041, 77.1025, 'NCR • National Capital'),
                _buildCityButton('💎 Hyderabad', 17.3850, 78.4867, 'Telangana • Cyberabad'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildCityButton(String city, double lat, double lng, String subtitle) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _setManualLocation(lat, lng, city.replaceAll(RegExp(r'[🏭🌆🏖️🏙️🏛️💎]\s*'), ''));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              city, 
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  void _setManualLocation(double lat, double lng, String cityName) {
    print('📍 MANUAL LOCATION: User set location to $cityName ($lat, $lng)');
    setState(() {
      _currentPosition = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      _statusMessage = 'Location set to $cityName\nSearching for stores...';
    });

    _searchNearbyStores();
  }

  // Helper methods for store actions
  Future<void> _openGoogleMaps(ConstructionStore store) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${store.latitude},${store.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _callStore(ConstructionStore store) async {
    if (store.phoneNumber != null && store.phoneNumber!.isNotEmpty) {
      final url = 'tel:${store.phoneNumber}';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()}m away';
    } else {
      return '${distanceKm.toStringAsFixed(1)}km away';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Nearby Stores'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: _currentPosition == null 
        ? _buildPermissionRequestView() 
        : _buildSearchResultsView(),
    );
  }

  /// View shown BEFORE a location is acquired.
  Widget _buildPermissionRequestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on, color: Colors.orange, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Find Construction Stores Near You',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'We\'ll automatically find your precise location and show you the closest stores.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (_isLoading) ...[
              const CircularProgressIndicator(color: Colors.orange),
              const SizedBox(height: 16),
              Text(_statusMessage, textAlign: TextAlign.center, style: TextStyle(color: Colors.orange.shade700)),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _getUserLocationAndSearch,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Find Stores Near Me'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _showManualLocationPicker,
                icon: const Icon(Icons.edit_location, size: 18),
                label: const Text('Or set location manually'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            
            if (_statusMessage.isNotEmpty && !_isLoading) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('Simulator') 
                    ? Colors.orange.shade50 
                    : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage.contains('Simulator') 
                      ? Colors.orange.shade200 
                      : Colors.red.shade200
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage.contains('Simulator') 
                        ? Icons.info_outline 
                        : Icons.error_outline,
                      color: _statusMessage.contains('Simulator') 
                        ? Colors.orange.shade700 
                        : Colors.red.shade700,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage, 
                        style: TextStyle(
                          color: _statusMessage.contains('Simulator') 
                            ? Colors.orange.shade700 
                            : Colors.red.shade700
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  /// View shown AFTER a location is acquired.
  Widget _buildSearchResultsView() {
    return Column(
      children: [
        // Search bar and location info
        Container(
          color: Colors.grey.shade50,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for specific materials or stores...',
                  prefixIcon: const Icon(Icons.search, color: Colors.orange),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchNearbyStores();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _searchNearbyStores(),
              ),
              
              const SizedBox(height: 12),
              
              // Status and action buttons
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showManualLocationPicker,
                    icon: const Icon(Icons.edit_location, size: 18),
                    label: const Text('Change'),
                    style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Results area
        Expanded(
          child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text('Searching for stores...'),
                  ],
                ),
              )
            : _stores.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No stores found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search terms or location.',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stores.length,
                  itemBuilder: (context, index) {
                    final store = _stores[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Store name and rating
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    store.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (store.rating > 0) ...[
                                  Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    store.rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Address
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    store.address,
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Action buttons
                            Row(
                              children: [
                                // Distance info
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _formatDistance(store.distance),
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                
                                const Spacer(),
                                
                                // Action buttons
                                if (store.phoneNumber != null && store.phoneNumber!.isNotEmpty)
                                  IconButton(
                                    onPressed: () => _callStore(store),
                                    icon: const Icon(Icons.phone, color: Colors.green),
                                    tooltip: 'Call store',
                                  ),
                                IconButton(
                                  onPressed: () => _openGoogleMaps(store),
                                  icon: const Icon(Icons.directions, color: Colors.blue),
                                  tooltip: 'Get directions',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}