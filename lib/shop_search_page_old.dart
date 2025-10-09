// shop_search_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'location_service.dart';
import 'google_places_service.dart';

class ShopSearchPage extends StatefulWidget {
  const ShopSearchPage({super.key});

  @override
  State<ShopSearchPage> createState() => _ShopSearchPageState();
}

class _ShopSearchPageState extends State<ShopSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  
  List<ConstructionStore> _stores = [];
  bool _isLoading = false;
  bool _locationPermissionGranted = false;
  Position? _currentPosition;
  String _errorMessage = '';
  bool _isUsingSimulatorLocation = false;

  @override
  void initState() {
    super.initState();
    // Automatically check and request location when page loads
    _initializeLocationAndSearch();
  }

  Future<void> _initializeLocationAndSearch() async {
    print('🚀 App started - checking existing location permissions...');
    
    // Check if permission already exists
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      print('✅ Location permission already granted, auto-getting location...');
      setState(() {
        _locationPermissionGranted = true;
      });
      // Automatically get location and search since permission exists
      await _getLocationAndAutoSearch();
    } else {
      print('📍 No location permission - user needs to grant it');
      // Show a message but don't auto-request (let user tap button)
      setState(() {
        _errorMessage = 'Tap "Enable Location" to find stores near you, or use "Set Location" to search a specific area.';
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _locationPermissionGranted = false;
    });

    try {
      print('🚀 STEP 1: Starting permission request flow...');
      
      // Show loading state for permission request
      setState(() {
        _errorMessage = 'Requesting location permission...';
      });

      // Request permission (this shows the permission dialog)
      bool hasPermission = await LocationService.requestLocationPermission();
      
      if (!hasPermission) {
        print('❌ STEP 2: Permission denied by user');
        setState(() {
          _errorMessage = 'Location permission is required to find nearby stores.\n\n'
              'Please allow location access when prompted, or use "Set Location" to enter manually.';
          _isLoading = false;
        });
        return;
      }

      print('✅ STEP 2: Permission granted! Starting automatic location and search...');
      setState(() {
        _locationPermissionGranted = true;
        _errorMessage = 'Permission granted! Getting your location...';
      });

      // CRITICAL: Automatically get location and search immediately after permission
      await _getLocationAndAutoSearch();
      
    } catch (e) {
      print('❌ Error in permission request: $e');
      setState(() {
        _errorMessage = 'Error requesting location: $e\n\nTry using "Set Location" to enter your location manually.';
        _isLoading = false;
      });
    }
  }

  Future<void> _getLocationAndAutoSearch() async {
    try {
      print('🌍 STEP 3: Getting current location...');
      
      setState(() {
        _errorMessage = 'Getting your current location...';
      });

      Position? position = await LocationService.getCurrentLocation();
      
      if (position == null) {
        print('❌ STEP 4: Failed to get location');
        setState(() {
          _errorMessage = 'Unable to get your current location.\n\n'
              'Try:\n'
              '• Check location permissions in Settings\n'
              '• On iOS Simulator: Features → Location → Apple\n'
              '• Or use "Set Location" to enter manually';
          _isLoading = false;
        });
        return;
      }

      print('✅ STEP 4: Got location - ${position.latitude}, ${position.longitude}');
      
      // Check if this looks like a simulator location
      bool isSimulatorLocation = _isDefaultSimulatorLocation(position);
      
      setState(() {
        _currentPosition = position;
        _isUsingSimulatorLocation = isSimulatorLocation;
        _errorMessage = isSimulatorLocation 
          ? 'Found location (simulator): ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}\nSearching for stores...'
          : 'Found your location: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}\nSearching for stores...';
      });

      print('🔍 STEP 5: Starting automatic store search...');
      
      // CRITICAL: Automatically search for stores with the location we got
      await _searchNearbyStores();
      
    } catch (e) {
      print('❌ Error getting location: $e');
      setState(() {
        _errorMessage = 'Error getting location: $e\n\nTry using "Set Location" to enter your location manually.';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchNearbyStores() async {
    if (_currentPosition == null) {
      print('❌ No current position available for search');
      return;
    }

    // Keep loading state but update message
    setState(() {
      _errorMessage = 'Finding nearby construction stores...';
    });

    try {
      print('🔍 STEP 6: Searching for stores near ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      
      List<ConstructionStore> stores = await GooglePlacesService.searchNearbyStores(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        query: _searchController.text.isNotEmpty ? _searchController.text : 'construction supply store',
      );

      print('✅ STEP 7: Found ${stores.length} stores from backend API');
      
      setState(() {
        _stores = stores;
        _isLoading = false; // Stop loading here
        if (stores.isEmpty) {
          _errorMessage = 'No construction stores found in this area.\n'
              'Try:\n'
              '• Expanding search radius\n'
              '• Using a different location\n'
              '• Searching for "hardware store" instead';
        } else {
          _errorMessage = ''; // Clear error message when stores are found
        }
      });

      print('🎉 STEP 8: Auto-search complete! Displaying ${stores.length} stores to user');
      
    } catch (e) {
      print('❌ Error searching for stores: $e');
      setState(() {
        _errorMessage = 'Error searching for stores: $e\n\nBackend connection issue. Check if server is running.';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchByText(String searchText) async {
    if (_currentPosition == null || searchText.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<ConstructionStore> stores = await GooglePlacesService.searchStoresByText(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        searchText: searchText.trim(),
      );

      setState(() {
        _stores = stores;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching: $e';
        _isLoading = false;
      });
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  bool _isDefaultSimulatorLocation(Position position) {
    // Common simulator default coordinates
    final lat = position.latitude;
    final lng = position.longitude;
    
    // San Francisco (default iOS simulator)
    if ((lat - 37.7749).abs() < 0.1 && (lng + 122.4194).abs() < 0.1) return true;
    if ((lat - 37.7858).abs() < 0.1 && (lng + 122.4064).abs() < 0.1) return true;
    
    // Cupertino (Apple HQ)
    if ((lat - 37.3230).abs() < 0.1 && (lng + 122.0322).abs() < 0.1) return true;
    
    // Exact coordinates that seem too precise (simulator often returns these)
    if (lat == 37.7858 && lng == -122.4064) return true;
    
    return false;
  }

  Future<void> _showLocationPicker() async {
    final TextEditingController latController = TextEditingController();
    final TextEditingController lngController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Your Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a city or enter coordinates:'),
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
                _buildCityButton('Pune', 18.5204, 73.8567),
              ],
            ),
            
            const SizedBox(height: 16),
            const Text('Or enter coordinates manually:'),
            const SizedBox(height: 8),
            
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g., 12.9716',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lngController,
              decoration: const InputDecoration(
                labelText: 'Longitude', 
                hintText: 'e.g., 77.5946',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final lat = double.tryParse(latController.text);
              final lng = double.tryParse(lngController.text);
              
              if (lat != null && lng != null) {
                _setManualLocation(lat, lng);
                Navigator.pop(context);
              }
            },
            child: const Text('Search Here'),
          ),
        ],
      ),
    );
  }

  Widget _buildCityButton(String city, double lat, double lng) {
    return ElevatedButton(
      onPressed: () {
        _setManualLocation(lat, lng);
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

  void _setManualLocation(double lat, double lng) {
    print('📍 MANUAL: Setting location to: $lat, $lng');
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
      _isUsingSimulatorLocation = false;
      _locationPermissionGranted = true;
      _isLoading = true; // Show loading for manual search too
      _errorMessage = 'Location set to $lat, $lng. Searching for nearby stores...';
    });
    
    print('🔍 MANUAL: Starting store search for manually set location...');
    // Immediately search for stores at this location
    _searchNearbyStores();
  }

  Future<void> _forcePermissionRequest() async {
    // Use our improved permission request method
    print('🔄 Force permission request triggered by user');
    await _requestLocationPermission();
  }

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
              onSubmitted: (text) => _searchByText(text),
            ),
          ),
          
          // Location Status Indicator
          if (_currentPosition != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isUsingSimulatorLocation ? Colors.orange.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isUsingSimulatorLocation ? Colors.orange : Colors.green,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isUsingSimulatorLocation ? Icons.warning : Icons.location_on,
                    color: _isUsingSimulatorLocation ? Colors.orange : Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isUsingSimulatorLocation 
                        ? 'Using simulator location (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})'
                        : 'Searching near your location (${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)})',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isUsingSimulatorLocation ? Colors.orange.shade800 : Colors.green.shade800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _showLocationPicker,
                    icon: Icon(
                      Icons.edit_location,
                      size: 16,
                      color: _isUsingSimulatorLocation ? Colors.orange : Colors.green,
                    ),
                    tooltip: 'Change location',
                  ),
                ],
              ),
            ),

          // Location Permission Request
          if (!_locationPermissionGranted && !_isLoading)
            Container(
              margin: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(Icons.location_off, color: Colors.orange, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'Location Permission Required',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap the button below to request location access and show nearby construction stores',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _forcePermissionRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.gps_fixed),
                          label: const Text('Request Location Permission'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This will show iOS location permission dialog',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _showLocationPicker,
                        child: const Text(
                          'Skip and set location manually',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Current Location Display with Simulator Warning
          if (_locationPermissionGranted && _currentPosition != null && !_isLoading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: _isUsingSimulatorLocation ? Colors.orange[50] : Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isUsingSimulatorLocation ? Icons.warning : Icons.location_on, 
                            color: _isUsingSimulatorLocation ? Colors.orange : Colors.green, 
                            size: 20
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isUsingSimulatorLocation 
                                ? 'Using simulator location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                                : 'Searching near: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      if (_isUsingSimulatorLocation) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'To get permission popup in iOS Simulator:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '1. Simulator → Device → Erase All Content and Settings\n'
                                '2. Restart app\n'
                                '3. Simulator → Features → Location → Apple',
                                style: TextStyle(fontSize: 10, color: Colors.blue[600]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: _showLocationPicker,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.orange[100],
                                ),
                                child: const Text('Set Real Location', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextButton(
                                onPressed: _forcePermissionRequest,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.blue[100],
                                ),
                                child: const Text('Retry Permission', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_errorMessage)),
                    ],
                  ),
                ),
              ),
            ),

          // Loading Indicator
          if (_isLoading)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.orange),
                    SizedBox(height: 16),
                    Text('Finding nearby stores...'),
                  ],
                ),
              ),
            ),

          // Store Results
          if (!_isLoading && _stores.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _stores.length,
                itemBuilder: (context, index) {
                  final store = _stores[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: store.isOpen ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  store.isOpen ? 'Open' : 'Closed',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            store.address,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (store.rating > 0) ...[
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(store.rating.toStringAsFixed(1)),
                                const SizedBox(width: 16),
                              ],
                              Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                              const SizedBox(width: 4),
                              Text(_formatDistance(store.distance)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openGoogleMaps(store),
                                  icon: const Icon(Icons.directions),
                                  label: const Text('Directions'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (store.phoneNumber != null)
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _callStore(store.phoneNumber),
                                    icon: const Icon(Icons.phone),
                                    label: const Text('Call'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
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

          // No Results
          if (!_isLoading && _stores.isEmpty && _locationPermissionGranted)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.store_mall_directory, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No construction stores found nearby',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    Text(
                      'Try searching for specific materials or expand your search',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _searchNearbyStores,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh Search'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}