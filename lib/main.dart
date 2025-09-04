import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './data/models.dart';
import './data/mock_data.dart';
import './store_details_page.dart';
import './auth_service.dart';
import './user_profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Building Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const SearchPage(),
    const QuestionnairePage(),
    const FavoritesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _residentialController;
  late Animation<double> _residentialScale;

  late AnimationController _commercialController;
  late Animation<double> _commercialScale;

  bool _isResidentialHovered = false;
  bool _isCommercialHovered = false;

  @override
  void initState() {
    super.initState();
    _residentialController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _commercialController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _residentialScale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _residentialController,
      curve: Curves.easeInOut,
    ));

    _commercialScale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _commercialController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _residentialController.dispose();
    _commercialController.dispose();
    super.dispose();
  }

  void _navigateToResidential() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PremierConstructionPage(
          title: 'Residential Construction',
          tagline: 'Building dream homes with exceptional craftsmanship and attention to detail since 1999.',
          type: 'residential',
        ),
      ),
    );
  }

  void _navigateToCommercial() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PremierConstructionPage(
          title: 'Commercial Construction',
          tagline: 'Delivering exceptional commercial projects with precision and innovation since 1999.',
          type: 'commercial',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Two Full Screen Sections (matching the image)
            Expanded(
              child: Column(
                children: [
                  // Residential Section (Top Half)
                  Expanded(
                    child: MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _isResidentialHovered = true;
                          _isCommercialHovered = false;
                        });
                        _residentialController.forward();
                        _commercialController.reverse();
                      },
                      onExit: (_) {
                        setState(() {
                          _isResidentialHovered = false;
                        });
                        _residentialController.reverse();
                      },
                      child: GestureDetector(
                        onTap: _navigateToResidential,
                        child: AnimatedBuilder(
                          animation: _residentialScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _residentialScale.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                        'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'For Home Builders',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Perfect solutions for residential projects and homeowners',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Text(
                                              'Explore Solutions',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: const Color(0xFFFFD700),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward,
                                              color: Color(0xFFFFD700),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Align(
                                          alignment: Alignment.bottomLeft,
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFD700),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward,
                                              color: Colors.black,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  // Commercial Section (Bottom Half)
                  Expanded(
                    child: MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _isCommercialHovered = true;
                          _isResidentialHovered = false;
                        });
                        _commercialController.forward();
                        _residentialController.reverse();
                      },
                      onExit: (_) {
                        setState(() {
                          _isCommercialHovered = false;
                        });
                        _commercialController.reverse();
                      },
                      child: GestureDetector(
                        onTap: _navigateToCommercial,
                        child: AnimatedBuilder(
                          animation: _commercialScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _commercialScale.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'For Commercial',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Comprehensive solutions for commercial and corporate projects',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            Text(
                                              'Explore Solutions',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: const Color(0xFFFFD700),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward,
                                              color: Color(0xFFFFD700),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Align(
                                          alignment: Alignment.bottomLeft,
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFD700),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward,
                                              color: Colors.black,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  late List<ConstructionStore> _allStores;
  List<ConstructionStore> _filteredStores = [];

  @override
  void initState() {
    super.initState();
    _allStores = MockDataService.getStores();
    _filteredStores = _allStores;
    _searchController.addListener(_filterStores);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStores);
    _searchController.dispose();
    super.dispose();
  }

  void _filterStores() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStores = _allStores.where((store) {
        final storeName = store.name.toLowerCase();
        final storeLocation = store.location.toLowerCase();
        return storeName.contains(query) || storeLocation.contains(query);
      }).toList();
    });
  }

  void _navigateToStoreDetails(ConstructionStore store) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoreDetailsPage(store: store),
      ),
    ).then((_) => setState(() {})); // Rebuild to reflect favorite changes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Find a Store',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Search for construction materials in Tamil Nadu.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by store name or city...',
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: _filteredStores.length,
                  itemBuilder: (context, index) {
                    final store = _filteredStores[index];
                    return GestureDetector(
                      onTap: () => _navigateToStoreDetails(store),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.1),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Image.network(
                                store.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.store,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                store.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
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
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, Icons.home, 'Home', 0),
                _buildNavItem(context, Icons.search, 'Search', 1),
                _buildNavItem(context, Icons.help_outline, 'Questionnaire', 2),
                _buildNavItem(context, Icons.favorite_border, 'Favorites', 3),
                _buildNavItem(context, Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final bool isActive = index == 1; // Search page is active
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        } else if (index == 2) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const QuestionnairePage()),
          );
        } else if (index == 3) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const FavoritesPage()),
          );
        } else if (index == 4) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
        // index == 1 is Search, do nothing (already on this page)
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionnairePage extends StatelessWidget {
  const QuestionnairePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Questionnaire',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
              ),
              const SizedBox(height: 40),
              Icon(
                Icons.assignment,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Questionnaire feature coming soon!',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, Icons.home, 'Home', 0),
                _buildNavItem(context, Icons.search, 'Search', 1),
                _buildNavItem(context, Icons.help_outline, 'Questionnaire', 2),
                _buildNavItem(context, Icons.favorite_border, 'Favorites', 3),
                _buildNavItem(context, Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final bool isActive = index == 2; // Questionnaire page is active
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        } else if (index == 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
        } else if (index == 3) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const FavoritesPage()),
          );
        } else if (index == 4) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
        // index == 2 is Questionnaire, do nothing (already on this page)
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Product> _favoritedProducts = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    setState(() {
      _favoritedProducts = MockDataService.getFavoritedProducts();
    });
  }

  void _toggleFavorite(String productId) {
    setState(() {
      MockDataService.toggleFavoriteStatus(productId);
      _loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favorite Products',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
              ),
              const SizedBox(height: 20),
              _favoritedProducts.isEmpty
                  ? Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No favorites yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                            ),
                            const Text(
                              'Tap the heart icon on a product to save it.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _favoritedProducts.length,
                        itemBuilder: (context, index) {
                          final product = _favoritedProducts[index];
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
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: const Icon(
                                        Icons.shopping_bag,
                                        color: Colors.grey,
                                        size: 24,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              title: Text(product.name),
                              subtitle: Text('₹${product.price.toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.favorite, color: Colors.redAccent),
                                onPressed: () => _toggleFavorite(product.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(context, Icons.home, 'Home', 0),
                _buildNavItem(context, Icons.search, 'Search', 1),
                _buildNavItem(context, Icons.help_outline, 'Questionnaire', 2),
                _buildNavItem(context, Icons.favorite_border, 'Favorites', 3),
                _buildNavItem(context, Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final bool isActive = index == 3; // Favorites page is active
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        } else if (index == 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
        } else if (index == 2) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const QuestionnairePage()),
          );
        } else if (index == 4) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
        // index == 3 is Favorites, do nothing (already on this page)
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Replace the ENTIRE ProfilePage widget (both State and StatefulWidget)
// with this new version. It will now act as a router.
class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    setState(() {
      // Rebuild the widget when auth state changes
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_authService.isLoggedIn) {
      return const UserProfilePage();
    } else {
      return const LoginSignUpPage();
    }
  }
}

// Create this new widget for the Login/SignUp UI.
// This is the content that was previously inside your ProfilePage.
class LoginSignUpPage extends StatefulWidget {
  const LoginSignUpPage({super.key});

  @override
  State<LoginSignUpPage> createState() => _LoginSignUpPageState();
}

class _LoginSignUpPageState extends State<LoginSignUpPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupNameController = TextEditingController();
  bool _isLoginPasswordVisible = false;
  bool _isSignupPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupNameController.dispose();
    super.dispose();
  }

  // Define your _handleGoogleSignIn and other button press methods here.
  // Make sure they call the AuthService on success.
  
  void _handleEmailLogin() {
    if (_loginFormKey.currentState!.validate()) {
      AuthService().mockSignIn(_loginEmailController.text, _loginEmailController.text);
    }
  }
  
  void _handleEmailSignUp() {
     if (_signupFormKey.currentState!.validate()) {
      AuthService().mockSignIn(_signupNameController.text, _signupEmailController.text);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    print('_handleGoogleSignIn function called!');
    const storage = FlutterSecureStorage();
    const serverUrl = 'http://127.0.0.1:8080'; // Use 127.0.0.1 for iOS simulator
    const googleWebClientId = '137371359979-uteh19od42d7hjal2s75ifcbf8329i5i.apps.googleusercontent.com'; // Real Google Client ID

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: googleWebClientId);

    try {
      // First, check if user is already signed in
      GoogleSignInAccount? currentUser = await googleSignIn.signInSilently();
      
      if (currentUser != null) {
        print('User already signed in: ${currentUser.email}');
        // User is already signed in, get fresh authentication
        final GoogleSignInAuthentication googleAuth = await currentUser.authentication;
        final String? idToken = googleAuth.idToken;
        
        if (idToken != null) {
          // Continue with backend authentication
          final response = await http.post(
            Uri.parse('$serverUrl/api/v1/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await storage.write(key: 'jwt_token', value: data['token']);
            
            // Create user model and sign in
            final user = UserModel(
              uid: data['user']['uid'] ?? '',
              name: data['user']['name'] ?? 'Unknown User',
              email: data['user']['email'] ?? '',
              photoUrl: data['user']['photoUrl'],
            );
            
            AuthService().signInWithGoogle(user);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Welcome back!'), backgroundColor: Colors.green),
              );
            }
            return;
          }
        }
      }

      print('Attempting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      print('Google Sign-In result: $googleUser');
      if (googleUser == null) {
        // User cancelled the sign-in
        print('User cancelled Google Sign-In');
        return;
      }

      print('Google Sign-In successful for: ${googleUser.email}');

      // Try to obtain a valid ID token reliably across iOS/Android
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      String? idToken = googleAuth.idToken;

      // Fallbacks: sometimes idToken can be null on iOS if the token is stale
      if (idToken == null) {
        print('Primary idToken was null, attempting silent re-authentication...');
        final GoogleSignInAccount? refreshedUser = await googleSignIn.signInSilently();
        if (refreshedUser != null) {
          googleAuth = await refreshedUser.authentication;
          idToken = googleAuth.idToken;
        }
      }
      if (idToken == null && googleSignIn.currentUser != null) {
        print('Attempting to fetch authentication from currentUser...');
        googleAuth = await googleSignIn.currentUser!.authentication;
        idToken = googleAuth.idToken;
      }

      if (idToken == null) {
        throw Exception('Could not retrieve ID token. Please ensure the iOS reversed client ID and Web client ID are configured correctly.');
      }

      print('Sending ID token to backend...');
      final response = await http.post(
        Uri.parse('$serverUrl/api/v1/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'jwt_token', value: data['token']);
        
        // Create user model and sign in
        final user = UserModel(
          uid: data['user']['uid'],
          name: data['user']['name'],
          email: data['user']['email'],
          photoUrl: data['user']['photoUrl'],
        );
        
        AuthService().signInWithGoogle(user);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully signed in!'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Backend authentication failed: ${response.body}');
      }
    } catch (error) {
      print('Google Sign-In error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Paste the full build method and all helper methods
  // from your OLD _ProfilePageState here.
  // IMPORTANT: For the regular login/signup buttons, change their `onPressed`
  // handlers to call `_handleEmailLogin()` and `_handleEmailSignUp()` respectively.
  // And for the Google login/signup buttons, change their `onTap` to call `_handleGoogleSignIn()`.
  
   @override
  Widget build(BuildContext context) {
    // This is where you paste the ENTIRE UI from your previous ProfilePage
    // (the one with the TabController, TextFormFields, etc.)
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient background similar to HomePage
            Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E3A8A),
                    const Color(0xFF1E3A8A).withOpacity(0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Header content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Building Platform',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Construction Partner',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab selector
            Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(16),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF1E3A8A),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Login'),
                  Tab(text: 'Sign Up'),
                ],
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildSignUpTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProfileNavItem(Icons.home, 'Home', 0),
                _buildProfileNavItem(Icons.search, 'Search', 1),
                _buildProfileNavItem(Icons.help_outline, 'Questionnaire', 2),
                _buildProfileNavItem(Icons.favorite_border, 'Favorites', 3),
                _buildProfileNavItem(Icons.person, 'Profile', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome Back!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to access your building projects',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Email TextField
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextFormField(
                controller: _loginEmailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(
                    Icons.email_outlined, 
                    color: const Color(0xFF1E3A8A).withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  labelStyle: TextStyle(color: const Color(0xFF1E3A8A)),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Password TextField
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextFormField(
                controller: _loginPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: Icon(
                    Icons.lock_outlined, 
                    color: const Color(0xFF1E3A8A).withOpacity(0.7),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isLoginPasswordVisible 
                        ? Icons.visibility_outlined 
                        : Icons.visibility_off_outlined,
                      color: const Color(0xFF1E3A8A).withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _isLoginPasswordVisible = !_isLoginPasswordVisible;
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  labelStyle: TextStyle(color: const Color(0xFF1E3A8A)),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                obscureText: !_isLoginPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Forgot Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Forgot password functionality coming soon!'),
                      backgroundColor: Color(0xFF1E3A8A),
                    ),
                  );
                },
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: const Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Login Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E3A8A),
                    const Color(0xFF1E3A8A).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleEmailLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Don't have account text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(1);
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Social Login Buttons
            Row(
              children: [
                // Apple Login Button
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Apple login coming soon!'),
                            backgroundColor: Color(0xFF1E3A8A),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.apple,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Apple',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Google Login Button  
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        print('Google Sign-In button tapped!');
                        _handleGoogleSignIn();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://developers.google.com/identity/images/g-logo.png',
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Google',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create Account',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF1E3A8A),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Join our building platform community',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Full Name TextField
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextFormField(
                controller: _signupNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icon(
                    Icons.person_outline, 
                    color: const Color(0xFF1E3A8A).withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  labelStyle: TextStyle(color: const Color(0xFF1E3A8A)),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your full name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Email TextField
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextFormField(
                controller: _signupEmailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email address',
                  prefixIcon: Icon(
                    Icons.email_outlined, 
                    color: const Color(0xFF1E3A8A).withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  labelStyle: TextStyle(color: const Color(0xFF1E3A8A)),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 20),
            
            // Password TextField
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextFormField(
                controller: _signupPasswordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Create a secure password',
                  prefixIcon: Icon(
                    Icons.lock_outlined, 
                    color: const Color(0xFF1E3A8A).withOpacity(0.7),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isSignupPasswordVisible 
                        ? Icons.visibility_outlined 
                        : Icons.visibility_off_outlined,
                      color: const Color(0xFF1E3A8A).withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _isSignupPasswordVisible = !_isSignupPasswordVisible;
                      });
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(20),
                  labelStyle: TextStyle(color: const Color(0xFF1E3A8A)),
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                obscureText: !_isSignupPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please create a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // Sign Up Button
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E3A8A),
                    const Color(0xFF1E3A8A).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _handleEmailSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Already have account text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Social Sign Up Buttons
            Row(
              children: [
                // Apple Sign Up Button
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Apple sign up coming soon!'),
                            backgroundColor: Color(0xFF1E3A8A),
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.apple,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Apple',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Google Sign Up Button  
                Expanded(
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        print('Google Sign-In button tapped!');
                        _handleGoogleSignIn();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://developers.google.com/identity/images/g-logo.png',
                                ),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Google',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(IconData icon, String label, int index) {
    final bool isActive = index == 4;
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else if (index == 1) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
        } else if (index == 2) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const QuestionnairePage()),
          );
        } else if (index == 3) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const FavoritesPage()),
          );
        }
        // index == 4 is Profile, do nothing
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? const Color(0xFF1E3A8A) : Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class FirstTimeUserForm extends StatefulWidget {
  const FirstTimeUserForm({super.key});

  @override
  State<FirstTimeUserForm> createState() => _FirstTimeUserFormState();
}

class _FirstTimeUserFormState extends State<FirstTimeUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _selectedState;
  String? _selectedCity;
  String? _selectedGender;
  DateTime? _selectedDate;
  String? _selectedContactTime;

  final Map<String, List<String>> _stateCities = {
    'Tamil Nadu': [
      'Chennai', 'Coimbatore', 'Madurai', 'Salem', 'Tiruchirappalli',
      'Vellore', 'Erode', 'Tiruppur', 'Dindigul', 'Thoothukkudi'
    ],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Thane'],
    'Delhi': ['New Delhi', 'Old Delhi'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Complete Profile',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E3A8A),
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader('Personal Information'),
                    const SizedBox(height: 16),
                    
                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildInputDecoration('Full Name', 'Enter your full name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _buildInputDecoration('Phone Number', 'Enter your phone number'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Email Address
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration('Email Address', 'Enter your email address'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _buildInputDecoration('Password', 'Enter your password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader('Location Information'),
                    const SizedBox(height: 16),
                    
                    // State Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      decoration: _buildInputDecoration('State', 'Select your state'),
                      items: _stateCities.keys.map((String state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedState = newValue;
                          _selectedCity = null; // Reset city when state changes
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // City Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: _buildInputDecoration('City', 'Select your city'),
                      items: _selectedState != null
                          ? _stateCities[_selectedState]!.map((String city) {
                              return DropdownMenuItem<String>(
                                value: city,
                                child: Text(city),
                              );
                            }).toList()
                          : [],
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCity = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select your city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    _buildSectionHeader('Additional Information'),
                    const SizedBox(height: 16),
                    
                    // Gender Radio Buttons
                    Text(
                      'Gender',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Male'),
                            value: 'Male',
                            groupValue: _selectedGender,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            activeColor: const Color(0xFF1E3A8A),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Female'),
                            value: 'Female',
                            groupValue: _selectedGender,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            activeColor: const Color(0xFF1E3A8A),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Other'),
                            value: 'Other',
                            groupValue: _selectedGender,
                            onChanged: (String? value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            activeColor: const Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Date of Birth
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
                          firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[50],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate != null
                                  ? 'Date of Birth: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                  : 'Date of Birth',
                              style: TextStyle(
                                color: _selectedDate != null ? Colors.black : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Address
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: _buildInputDecoration('Address', 'Enter your complete address'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Preferred Contact Time
                    DropdownButtonFormField<String>(
                      value: _selectedContactTime,
                      decoration: _buildInputDecoration('Preferred Contact Time', 'Select preferred time'),
                      items: ['Morning', 'Afternoon', 'Evening'].map((String time) {
                        return DropdownMenuItem<String>(
                          value: time,
                          child: Text(time),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedContactTime = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select preferred contact time';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 100), // Extra space for submit button
                  ],
                ),
              ),
            ),
            // Fixed Submit Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Handle form submission
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile completed successfully!'),
                        backgroundColor: Color(0xFF1E3A8A),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E3A8A),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A)),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.all(16),
    );
  }
}

class PremierConstructionPage extends StatefulWidget {
  final String title;
  final String tagline;
  final String type;

  const PremierConstructionPage({
    super.key,
    required this.title,
    required this.tagline,
    required this.type,
  });

  @override
  State<PremierConstructionPage> createState() => _PremierConstructionPageState();
}

class _PremierConstructionPageState extends State<PremierConstructionPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section with Back Button
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Residential Construction',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Building dream homes with exceptional craftsmanship and attention to detail since 1999.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Statistics Section - Two rows of two cards
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // First row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.home,
                          number: '150+',
                          label: 'Projects\nCompleted',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.emoji_events,
                          number: '25',
                          label: 'Years\nExperience',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Second row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.people,
                          number: '200+',
                          label: 'Satisfied\nClients',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.calendar_today,
                          number: '98%',
                          label: 'On-Time\nDelivery',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Projects Section - Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Previous Projects',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore our portfolio of completed residential construction projects, from luxury estates to custom renovations.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Horizontally scrollable project cards
                    SizedBox(
                      height: 320,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildProjectCard(
                            title: 'Modern Hillside Villa',
                            image: 'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                            label: 'New Construction',
                            location: 'Beverly Hills, CA',
                            description: 'A stunning 4,500 sq ft contemporary home with panoramic views and luxury amenities.',
                          ),
                          const SizedBox(width: 16),
                          _buildProjectCard(
                            title: 'Luxury Estate Residence',
                            image: 'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                            label: 'Luxury Home',
                            location: 'Malibu, CA',
                            description: 'An elegant 6,200 sq ft estate featuring custom finishes and ocean views.',
                          ),
                          const SizedBox(width: 16),
                          _buildProjectCard(
                            title: 'Contemporary Family Home',
                            image: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                            label: 'Custom Home',
                            location: 'Santa Monica, CA',
                            description: 'A modern 3,800 sq ft family residence with open concept living and smart home features.',
                          ),
                          const SizedBox(width: 16),
                          _buildProjectCard(
                            title: 'Beachfront Villa',
                            image: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                            label: 'Luxury Villa',
                            location: 'Laguna Beach, CA',
                            description: 'A spectacular 5,500 sq ft beachfront villa with infinity pool and private beach access.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32), // Extra padding for scroll
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', 0, const Color(0xFF1E3A8A)),
                _buildNavItem(Icons.search, 'Search', 1, Colors.grey[600]!),
                _buildNavItem(Icons.help_outline, 'Questionnaire', 2, Colors.grey[600]!),
                _buildNavItem(Icons.favorite_border, 'Favorites', 3, Colors.grey[600]!),
                _buildNavItem(Icons.person, 'Profile', 4, Colors.grey[600]!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String number,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF1E3A8A),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard({
    required String title,
    required String image,
    required String label,
    required String location,
    required String description,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with label
            Stack(
              children: [
                Image.network(
                  image,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'View Details',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward,
                        size: 16,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color color) {
    return GestureDetector(
      onTap: () {
        if (index == 0) {
          // Navigate back to Home
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        } else if (index == 1) {
          // Navigate to Search
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const SearchPage()),
          );
        } else if (index == 2) {
          // Navigate to Questionnaire
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const QuestionnairePage()),
          );
        } else if (index == 3) {
          // Navigate to Favorites
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const FavoritesPage()),
          );
        } else if (index == 4) {
          // Navigate to Profile
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const ProfilePage()),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _currentIndex == index ? const Color(0xFF1E3A8A) : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: _currentIndex == index ? const Color(0xFF1E3A8A) : Colors.grey[600],
              fontSize: 12,
              fontWeight: _currentIndex == index ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// 1. LoginPage widget
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    print('_handleGoogleSignIn function called!');
    const storage = FlutterSecureStorage();
    const serverUrl = 'http://127.0.0.1:8080'; // Use 127.0.0.1 for iOS simulator
    const googleWebClientId = '137371359979-uteh19od42d7hjal2s75ifcbf8329i5i.apps.googleusercontent.com'; // Real Google Client ID

    final GoogleSignIn googleSignIn = GoogleSignIn(serverClientId: googleWebClientId);

    try {
      // First, check if user is already signed in
      GoogleSignInAccount? currentUser = await googleSignIn.signInSilently();
      
      if (currentUser != null) {
        print('User already signed in: ${currentUser.email}');
        // User is already signed in, get fresh authentication
        final GoogleSignInAuthentication googleAuth = await currentUser.authentication;
        final String? idToken = googleAuth.idToken;
        
        if (idToken != null) {
          // Continue with backend authentication
          final response = await http.post(
            Uri.parse('$serverUrl/api/v1/auth/google'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'idToken': idToken}),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            await storage.write(key: 'jwt_token', value: data['token']);
            
            // Create user model and sign in
            final user = UserModel(
              uid: data['user']['uid'] ?? '',
              name: data['user']['name'] ?? 'Unknown User',
              email: data['user']['email'] ?? '',
              photoUrl: data['user']['photoUrl'],
            );
            
            AuthService().signInWithGoogle(user);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Welcome back!'), backgroundColor: Colors.green),
              );
            }
            return;
          }
        }
      }

      print('Attempting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      print('Google Sign-In result: $googleUser');
      if (googleUser == null) {
        // User cancelled the sign-in
        print('User cancelled Google Sign-In');
        return;
      }

      print('Google Sign-In successful for: ${googleUser.email}');

      // Try to obtain a valid ID token reliably across iOS/Android
      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      String? idToken = googleAuth.idToken;

      // Fallbacks: sometimes idToken can be null on iOS if the token is stale
      if (idToken == null) {
        print('Primary idToken was null, attempting silent re-authentication...');
        final GoogleSignInAccount? refreshedUser = await googleSignIn.signInSilently();
        if (refreshedUser != null) {
          googleAuth = await refreshedUser.authentication;
          idToken = googleAuth.idToken;
        }
      }
      if (idToken == null && googleSignIn.currentUser != null) {
        print('Attempting to fetch authentication from currentUser...');
        googleAuth = await googleSignIn.currentUser!.authentication;
        idToken = googleAuth.idToken;
      }

      if (idToken == null) {
        throw Exception('Could not retrieve ID token. Please ensure the iOS reversed client ID and Web client ID are configured correctly.');
      }

      print('Sending ID token to backend...');
      final response = await http.post(
        Uri.parse('$serverUrl/api/v1/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      print('Backend response status: ${response.statusCode}');
      print('Backend response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'jwt_token', value: data['token']);
        
        // Create user model and sign in
        final user = UserModel(
          uid: data['user']['uid'],
          name: data['user']['name'],
          email: data['user']['email'],
          photoUrl: data['user']['photoUrl'],
        );
        
        AuthService().signInWithGoogle(user);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully signed in!'), backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Backend authentication failed: ${response.body}');
      }
    } catch (error) {
      print('Google Sign-In error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient background similar to HomePage cards
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E3A8A),
                    const Color(0xFF1E3A8A).withOpacity(0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Back button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // Header content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.business,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Building Platform',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Welcome Back!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      
                      Text(
                        'Sign in to continue',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: const Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Access your building projects and manage your construction portfolio',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      // Email TextField
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter your email address',
                            prefixIcon: Icon(
                              Icons.email_outlined, 
                              color: const Color(0xFF1E3A8A).withOpacity(0.7),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                            labelStyle: TextStyle(color: const Color(0xFF1E3A8A)),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Password TextField
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outlined, 
                              color: const Color(0xFF1E3A8A).withOpacity(0.7),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible 
                                  ? Icons.visibility_outlined 
                                  : Icons.visibility_off_outlined,
                                color: const Color(0xFF1E3A8A).withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(20),
                            labelStyle: TextStyle(color: const Color(0xFF1E3A8A)),
                            hintStyle: TextStyle(color: Colors.grey[400]),
                          ),
                          obscureText: !_isPasswordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Forgot password functionality coming soon!'),
                                backgroundColor: Color(0xFF1E3A8A),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: const Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Login Button - matching your app's button style
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF1E3A8A),
                              const Color(0xFF1E3A8A).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Handle login
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Welcome back, ${_emailController.text}!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Divider with "or continue with"
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or continue with',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Social Login Buttons - matching your app's card style
                      Row(
                        children: [
                          // Google Login Button
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                        print('Google Sign-In button tapped!');
                        _handleGoogleSignIn();
                      },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            'https://developers.google.com/identity/images/g-logo.png',
                                          ),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Google',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          
                          // Facebook Login Button  
                          Expanded(
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Facebook login coming soon!'),
                                      backgroundColor: Color(0xFF1E3A8A),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.facebook,
                                      color: Color(0xFF1877F2),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Facebook',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sign up functionality coming soon!'),
                                  backgroundColor: Color(0xFF1E3A8A),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
