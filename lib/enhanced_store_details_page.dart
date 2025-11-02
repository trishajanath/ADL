// lib/enhanced_store_details_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'google_places_service.dart';

class EnhancedStoreDetailsPage extends StatefulWidget {
  final ConstructionStore store;

  const EnhancedStoreDetailsPage({super.key, required this.store});

  @override
  State<EnhancedStoreDetailsPage> createState() => _EnhancedStoreDetailsPageState();
}

class _EnhancedStoreDetailsPageState extends State<EnhancedStoreDetailsPage> {
  bool _isLoadingDetails = false;
  StoreDetails? _storeDetails;

  @override
  void initState() {
    super.initState();
    _loadStoreDetails();
  }

  Future<void> _loadStoreDetails() async {
    setState(() => _isLoadingDetails = true);
    
    try {
      final details = await GooglePlacesService.getStoreDetailsComplete(widget.store.placeId);
      setState(() {
        _storeDetails = details;
        _isLoadingDetails = false;
      });
      
      if (details != null) {
        print('✅ Loaded detailed information for ${details.name}');
      }
    } catch (e) {
      setState(() => _isLoadingDetails = false);
      print('Error loading store details: $e');
    }
  }

  Future<void> _openGoogleMaps() async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${widget.store.latitude},${widget.store.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Could not open Google Maps');
    }
  }

  Future<void> _getDirections() async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${widget.store.latitude},${widget.store.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Could not open directions');
    }
  }

  Future<void> _callStore() async {
    // Use detailed phone number if available, otherwise use basic store data
    String? phoneNumber = _storeDetails?.phoneNumber ?? widget.store.phoneNumber;
    
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      final url = 'tel:$phoneNumber';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showSnackBar('Could not make phone call');
      }
    } else {
      _showSnackBar('Phone number not available');
    }
  }

  Future<void> _openWebsite() async {
    // Use detailed website if available, otherwise use basic store data
    String? website = _storeDetails?.website ?? widget.store.website;
    
    if (website != null && website.isNotEmpty) {
      if (await canLaunchUrl(Uri.parse(website))) {
        await launchUrl(Uri.parse(website), mode: LaunchMode.externalApplication);
      } else {
        _showSnackBar('Could not open website');
      }
    } else {
      _showSnackBar('Website not available');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m away';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km away';
    }
  }

  // List of common construction materials for price reporting
  final List<String> _constructionProducts = [
    'Cement (50kg bag)',
    'TMT Steel (per kg)',
    'Bricks (per piece)',
    'Sand (per m³)',
    'Gravel (per m³)',
    'Concrete Blocks (per piece)',
    'Paint (per liter)',
    'Tiles (per sq ft)',
    'Pipes (per meter)',
    'Wire (per meter)',
  ];

  void _showPriceReportDialog() {
    String? selectedProduct;
    final priceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Report a New Price'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Help the community by reporting current prices at this store:'),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedProduct,
                    items: _constructionProducts.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Text(product),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedProduct = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹)',
                      border: OutlineInputBorder(),
                      prefixText: '₹ ',
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedProduct != null && priceController.text.isNotEmpty) {
                  final price = double.tryParse(priceController.text);
                  if (price != null && price > 0) {
                    Navigator.of(context).pop();
                    
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const AlertDialog(
                        content: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Submitting price report...'),
                          ],
                        ),
                      ),
                    );
                    
                    // Submit price report
                    bool success = await GooglePlacesService.reportPrice(
                      widget.store.placeId,
                      selectedProduct!,
                      price,
                    );
                    
                    Navigator.of(context).pop(); // Close loading dialog
                    
                    if (success) {
                      _showSnackBar('Price reported successfully! Thank you for contributing.');
                      _loadStoreDetails(); // Refresh the store details to show new price
                    } else {
                      _showSnackBar('Failed to report price. Please try again.');
                    }
                  } else {
                    _showSnackBar('Please enter a valid price');
                  }
                } else {
                  _showSnackBar('Please select a product and enter a price');
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStorePhoto() {
    if (widget.store.photos != null && widget.store.photos!.isNotEmpty) {
      return Container(
        height: 200,
        child: PageView.builder(
          itemCount: widget.store.photos!.length,
          itemBuilder: (context, index) {
            return Container(
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.store.photos![index]),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Photo counter indicator
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${index + 1}/${widget.store.photos!.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } else if (widget.store.photoReference != null) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(GooglePlacesService.getPhotoUrl(widget.store.photoReference!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[300],
        child: const Icon(
          Icons.store,
          size: 80,
          color: Colors.grey,
        ),
      );
    }
  }

  Widget _buildRatingStars(double rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      if (i <= rating) {
        stars.add(const Icon(Icons.star, color: Colors.amber, size: 20));
      } else if (i - 0.5 <= rating) {
        stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 20));
      } else {
        stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 20));
      }
    }
    return Row(children: stars);
  }

  Widget _buildCommunityPricesSection() {
    if (_storeDetails == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Community-Reported Prices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showPriceReportDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Report Price'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_storeDetails!.latestPrices.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.price_check, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No prices reported yet. Be the first!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Help the community by reporting current prices',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _storeDetails!.latestPrices.map((price) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.inventory,
                            color: Colors.green,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                price.productName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _formatTimeAgo(price.lastReported),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '₹${price.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return 'Reported ${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return 'Reported ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return 'Reported ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Reported just now';
      }
    } catch (e) {
      return 'Recently reported';
    }
  }

  Widget _buildActionButtons() {
    // Use detailed information if available
    String? phoneNumber = _storeDetails?.phoneNumber ?? widget.store.phoneNumber;
    String? website = _storeDetails?.website ?? widget.store.website;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _getDirections,
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text('Directions', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _callStore,
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text('Call', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          if (website != null && website.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openWebsite,
                icon: const Icon(Icons.language, color: Colors.white),
                label: const Text('Website', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    // Use detailed information if available, otherwise fallback to basic store data
    String storeName = _storeDetails?.name ?? widget.store.name;
    double storeRating = _storeDetails?.rating ?? widget.store.rating;
    int? userRatingsTotal = _storeDetails?.userRatingsTotal ?? widget.store.userRatingsTotal;
    String storeAddress = _storeDetails?.formattedAddress ?? widget.store.formattedAddress ?? widget.store.address;
    String? phoneNumber = _storeDetails?.phoneNumber ?? widget.store.phoneNumber;
    
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              storeName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRatingStars(storeRating),
                const SizedBox(width: 8),
                Text(
                  '$storeRating',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (userRatingsTotal != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    '($userRatingsTotal reviews)',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  widget.store.isOpen ? Icons.access_time : Icons.access_time_filled,
                  size: 18,
                  color: widget.store.isOpen ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.store.isOpen ? 'Open now' : 'Closed',
                  style: TextStyle(
                    color: widget.store.isOpen ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    storeAddress,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.navigation, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  _formatDistance(widget.store.distance),
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (phoneNumber != null && phoneNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    phoneNumber,
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOpeningHours() {
    // Use detailed opening hours if available, otherwise fallback to basic store data
    List<String>? openingHours = _storeDetails?.openingHours ?? widget.store.openingHours;
    
    if (openingHours == null || openingHours.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get current day of week (0 = Sunday, 1 = Monday, etc.)
    int currentDay = DateTime.now().weekday % 7; // Convert to 0-6 range
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Text(
                  'Opening Hours',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...openingHours.asMap().entries.map((entry) {
              int index = entry.key;
              String hours = entry.value;
              bool isToday = index == currentDay;
              
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue.shade50 : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday ? Border.all(color: Colors.blue.shade200) : null,
                ),
                child: Row(
                  children: [
                    if (isToday)
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        margin: const EdgeInsets.only(right: 8),
                      ),
                    Expanded(
                      child: Text(
                        hours,
                        style: TextStyle(
                          color: isToday ? Colors.blue.shade800 : Colors.grey[700],
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isToday)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    // Use detailed reviews if available, otherwise fallback to basic store data
    List<Map<String, dynamic>>? reviews = _storeDetails?.reviews ?? widget.store.reviews;
    int? userRatingsTotal = _storeDetails?.userRatingsTotal ?? widget.store.userRatingsTotal;
    
    if (reviews == null || reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.reviews, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Customer Reviews',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                if (userRatingsTotal != null)
                  Text(
                    '$userRatingsTotal reviews',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...reviews.take(3).map((review) => _buildReviewCard(review)),
            if (reviews.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'View ${reviews.length - 3} more reviews on Google Maps',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                  review['author_name'][0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['author_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review['rating'] ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          review['relative_time_description'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['text'],
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        title: const Text('Store Details'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _openGoogleMaps,
            icon: const Icon(Icons.map),
            tooltip: 'View on map',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStorePhoto(),
                  _buildInfoSection(),
                  _buildOpeningHours(),
                  _buildReviewsSection(),
                  _buildCommunityPricesSection(),
                  if (_isLoadingDetails)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  const SizedBox(height: 80), // Space for fixed bottom buttons
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildActionButtons(),
    );
  }
}