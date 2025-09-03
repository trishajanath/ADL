// lib/store_details_page.dart
import 'package:flutter/material.dart';
import './data/models.dart';
import './data/mock_data.dart';

class StoreDetailsPage extends StatefulWidget {
  final ConstructionStore store;

  const StoreDetailsPage({super.key, required this.store});

  @override
  State<StoreDetailsPage> createState() => _StoreDetailsPageState();
}

class _StoreDetailsPageState extends State<StoreDetailsPage> {
  void _toggleFavorite(String productId) {
    setState(() {
      MockDataService.toggleFavoriteStatus(productId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          widget.store.name,
          style: const TextStyle(color: Color(0xFF1E3A8A)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E3A8A)),
      ),
      body: ListView(
        children: [
          Image.network(
            widget.store.imageUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.store.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      widget.store.location,
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
                const Divider(height: 32),
                Text(
                  'Products Available',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),
                ...widget.store.products.map((product) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          product.imageUrl,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      title: Text(product.name),
                      subtitle: Text('₹${product.price.toStringAsFixed(2)}'),
                      trailing: IconButton(
                        icon: Icon(
                          product.isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: product.isFavorited ? Colors.redAccent : Colors.grey,
                        ),
                        onPressed: () => _toggleFavorite(product.id),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
