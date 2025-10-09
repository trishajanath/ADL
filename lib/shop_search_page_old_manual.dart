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
  Position? _currentPosition;
  String _statusMessage = ''; // User-facing status message

  /// This is the main function that handles the entire user flow.
  /// It's called when the user taps the "Use My Location" button.
  Future<void> _getUserLocationAndSearch() async {
    setState(() {
      _isLoading = true;
      _stores = [];
      _statusMessage = 'Requesting location permission...';
    });

    try {
      print('🎯 USER ACTION: Requesting location-based search');
      
      // 1. Request permission using your robust location_service.
      bool hasPermission = await LocationService.requestLocationPermission();
      
      if (!hasPermission) {
        setState(() {
          _statusMessage = 'Location permission is required to find nearby stores.';
          _isLoading = false;
        });
        return;
      }

      // 2. If permission is granted, get a FRESH, high-accuracy location.
      setState(() => _statusMessage = 'Permission granted! Fetching your location...');
      print('📍 Getting fresh high-accuracy location...');
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Force a high-accuracy request
        timeLimit: const Duration(seconds: 20), // Give it time to get a fix
      );
      
      print('✅ Fresh location: ${position.latitude}, ${position.longitude}');
      
      // Check if this looks like simulator coordinates
      bool isSimulator = _isSimulatorLocation(position);
      
      setState(() {
        _currentPosition = position;
        if (isSimulator) {
          _statusMessage = '⚠️ SIMULATOR DETECTED\nShowing San Francisco stores (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})\n\nFor your actual location, try on a real device.';
        } else {
          _statusMessage = 'Location found: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}\nSearching for stores...';
        }
      });

      // 3. Automatically search for stores with the newly acquired location.
      await _searchNearbyStores();

    } catch (e) {
      print('❌ Location error: $e');
      setState(() {
        _statusMessage = 'Error: Could not get location. Try using manual location selection.';
        _isLoading = false;
      });
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
    if (_currentPosition == null) return;

    // Use the search text if available, otherwise use a default query.
    String query = _searchController.text.trim().isEmpty 
                   ? "construction supply store" 
                   : _searchController.text.trim();

    setState(() {
      _statusMessage = "Searching for '$query' near your location...";
    });

    try {
      print('🔍 Searching for: $query near ${_currentPosition!.latitude}, ${_currentPosition!.longitude}');
      
      // Call your existing GooglePlacesService to talk to your backend.
      List<ConstructionStore> stores = await GooglePlacesService.searchNearbyStores(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        query: query,
      );

      print('✅ Found ${stores.length} stores');

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
      print('❌ Search error: $e');
      setState(() {
        _statusMessage = 'Error searching for stores: $e';
        _isLoading = false;
      });
    }
  }

  /// Show manual location picker for users who want to override GPS
  void _showManualLocationPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Your Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a city to search for stores:'),
            const SizedBox(height: 16),
            
            // Quick city buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCityButton('Coimbatore', 11.0168, 76.9558),
                _buildCityButton('Bangalore', 12.9716, 77.5946),
                _buildCityButton('Chennai', 13.0827, 80.2707),
                _buildCityButton('Mumbai', 19.0760, 72.8777),
                _buildCityButton('Delhi', 28.7041, 77.1025),
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
        Navigator.pop(context);
        _setManualLocation(lat, lng, city);
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

  /// This view is shown INITIALLY, before a location is acquired.
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
              'Discover hardware stores, building materials suppliers, and construction equipment dealers in your area.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (_isLoading) ...[
              const CircularProgressIndicator(color: Colors.orange),
              const SizedBox(height: 16),
              Text(_statusMessage, textAlign: TextAlign.center),
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
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showManualLocationPicker,
                  icon: const Icon(Icons.map),
                  label: const Text('Set Location Manually'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
            
            if (_statusMessage.isNotEmpty && !_isLoading) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _statusMessage, 
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  /// This view is shown AFTER a location has been successfully acquired.
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