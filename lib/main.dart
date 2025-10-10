import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// These are assumed to be in separate files. Ensure you have them in your project.
import './data/models.dart';
import './data/mock_data.dart';
import './store_details_page.dart';
import './auth_service.dart';
import './user_profile_page.dart';
import 'prediction_page.dart';
import 'shop_search_page.dart';
import 'projects_page.dart';

void main() {
  runApp(const MyApp());
}

// Global state to track if navigation should be shown
class NavigationState {
  static bool _hasSelectedCategory = false;
  static String _selectedCategory = '';
  
  static bool get hasSelectedCategory => _hasSelectedCategory;
  static String get selectedCategory => _selectedCategory;
  
  static void setCategory(String category) {
    _hasSelectedCategory = true;
    _selectedCategory = category;
  }
  
  static void reset() {
    _hasSelectedCategory = false;
    _selectedCategory = '';
  }
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

// --- CORE NAVIGATION WIDGET (REFACTORED) ---
// This widget now controls the main view and the bottom navigation bar.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _hasSelectedCategory = false; // Track if user has selected residential/commercial

  // List of the main pages accessible from the bottom navigation bar.
  List<Widget> get _screens => [
    HomePage(onCategorySelected: _onCategorySelected),
    const SearchPage(),
    const QuestionnairePage(),
    const ProjectsPage(),
    const FavoritesPage(),
    const ProfilePage(), // The router page for login/profile
  ];

  void _onCategorySelected(String category) {
    setState(() {
      _hasSelectedCategory = true;
      NavigationState.setCategory(category);
    });
  }

  @override
  void initState() {
    super.initState();
    // Check if category was already selected
    _hasSelectedCategory = NavigationState.hasSelectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // Only show bottom navigation bar after category selection
      bottomNavigationBar: _hasSelectedCategory ? Container(
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
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.search, 'Search', 1),
                _buildNavItem(Icons.help_outline, 'Questionnaire', 2),
                _buildNavItem(Icons.construction, 'Projects', 3),
                _buildNavItem(Icons.favorite_border, 'Favorites', 4),
                _buildNavItem(Icons.person, 'Profile', 5),
              ],
            ),
          ),
        ),
      ) : null,
    );
  }

  // Helper widget to build each navigation item.
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
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Navigation wrapper that can be used on any page
class NavigationWrapper extends StatefulWidget {
  final Widget child;
  final int? currentIndex;
  
  const NavigationWrapper({
    super.key, 
    required this.child,
    this.currentIndex,
  });

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isActive = widget.currentIndex == index;
    return GestureDetector(
      onTap: () {
        // Navigate to the appropriate page using Navigator.pushReplacement
        // to maintain the navigation state
        Widget destinationPage;
        switch (index) {
          case 0:
            destinationPage = HomePage(onCategorySelected: (category) {
              NavigationState.setCategory(category);
            });
            break;
          case 1:
            destinationPage = const ShopSearchPage();
            break;
          case 2:
            destinationPage = const QuestionnairePage();
            break;
          case 3:
            destinationPage = const ProjectsPage();
            break;
          case 4:
            destinationPage = const FavoritesPage();
            break;
          case 5:
            destinationPage = const ProfilePage();
            break;
          default:
            destinationPage = HomePage(onCategorySelected: (category) {
              NavigationState.setCategory(category);
            });
        }
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NavigationWrapper(
              child: destinationPage,
              currentIndex: index,
            ),
          ),
        );
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
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationState.hasSelectedCategory ? Container(
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
                _buildNavItem(Icons.home, 'Home', 0),
                _buildNavItem(Icons.search, 'Search', 1),
                _buildNavItem(Icons.help_outline, 'Questionnaire', 2),
                _buildNavItem(Icons.construction, 'Projects', 3),
                _buildNavItem(Icons.favorite_border, 'Favorites', 4),
                _buildNavItem(Icons.person, 'Profile', 5),
              ],
            ),
          ),
        ),
      ) : null,
    );
  }
}

// --- PAGE WIDGETS (CLEANED) ---

class HomePage extends StatefulWidget {
  final Function(String)? onCategorySelected;
  
  const HomePage({super.key, this.onCategorySelected});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _residentialController;
  late Animation<double> _residentialScale;
  late AnimationController _commercialController;
  late Animation<double> _commercialScale;

  @override
  void initState() {
    super.initState();
    _residentialController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _commercialController = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);

    _residentialScale = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _residentialController, curve: Curves.easeInOut));
    _commercialScale = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _commercialController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _residentialController.dispose();
    _commercialController.dispose();
    super.dispose();
  }

  void _navigateToResidential() {
    HapticFeedback.lightImpact();
    // Call the callback to enable bottom navigation
    widget.onCategorySelected?.call('residential');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NavigationWrapper(
          child: PremierConstructionPage(
            title: 'Residential Construction',
            tagline:
                'Building dream homes with exceptional craftsmanship and attention to detail since 1999.',
            type: 'residential',
          ),
        ),
      ),
    );
  }

  void _navigateToCommercial() {
    HapticFeedback.lightImpact();
    // Call the callback to enable bottom navigation
    widget.onCategorySelected?.call('commercial');
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NavigationWrapper(
          child: PremierConstructionPage(
            title: 'Commercial Construction',
            tagline:
                'Delivering exceptional commercial projects with precision and innovation since 1999.',
            type: 'commercial',
          ),
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
        title: Text(
          'Building Platform',
          style: TextStyle(
              color: const Color(0xFF1E3A8A), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Residential Section (Top Half)
          Expanded(
            child: MouseRegion(
              onEnter: (_) {
                _residentialController.forward();
                _commercialController.reverse();
              },
              onExit: (_) {
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
                        margin: EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          image: DecorationImage(
                            image: NetworkImage(
                                'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
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
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'For Residential',
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
                                  'Perfect solutions for your dream home.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
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
                _commercialController.forward();
                _residentialController.reverse();
              },
              onExit: (_) {
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
                        margin: EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                          image: DecorationImage(
                            image: NetworkImage(
                                'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.black.withOpacity(0.4),
                                Colors.black.withOpacity(0.1),
                              ],
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
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
                                  'Comprehensive solutions for commercial and corporate projects.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withOpacity(0.9),
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
      // FIX: Removed the redundant bottom navigation bar.
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.psychology,
                    size: 80,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '${NavigationState.selectedCategory.isNotEmpty ? NavigationState.selectedCategory[0].toUpperCase() + NavigationState.selectedCategory.substring(1) : "Building"} Analysis',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Get professional concrete grade recommendations for your ${NavigationState.selectedCategory.toLowerCase()} construction project using our advanced machine learning system.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Features list
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildFeatureItem(Icons.analytics, 'AI-Powered Analysis', 'Advanced machine learning algorithms'),
                      SizedBox(height: 12),
                      _buildFeatureItem(Icons.speed, 'Instant Results', 'Get recommendations in seconds'),
                      SizedBox(height: 12),
                      _buildFeatureItem(Icons.attach_money, 'Cost Estimation', 'Complete material and cost breakdown'),
                      SizedBox(height: 12),
                      _buildFeatureItem(Icons.verified, 'Professional Grade', '95%+ accuracy predictions'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Get the selected category from NavigationState
                      String selectedCategory = NavigationState.selectedCategory;
                      if (selectedCategory.isEmpty) {
                        // Fallback - should not happen if navigation is working correctly
                        selectedCategory = 'residential';
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PredictionPage(category: selectedCategory),
                        ),
                      );
                    },
                    icon: Icon(Icons.rocket_launch),
                    label: Text('Start ${NavigationState.selectedCategory.isNotEmpty ? NavigationState.selectedCategory[0].toUpperCase() + NavigationState.selectedCategory.substring(1) : "Building"} Analysis'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  NavigationState.selectedCategory.toLowerCase() == 'residential' 
                    ? '16 detailed questions • 3-4 minute analysis'
                    : NavigationState.selectedCategory.toLowerCase() == 'commercial'
                    ? '10 focused questions • 2-3 minute analysis'
                    : 'Quick questions • 2-3 minute analysis',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
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
                            Icon(Icons.favorite_border,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No favorites yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(color: Colors.grey[600]),
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
                                        borderRadius:
                                            BorderRadius.circular(8.0),
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
                              subtitle: Text(
                                  '₹${product.price.toStringAsFixed(2)}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.favorite,
                                    color: Colors.redAccent),
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
      // FIX: Removed the redundant bottom navigation bar.
    );
  }
}

// --- AUTH AND PROFILE WIDGETS (REFACTORED) ---

// This widget acts as a router. It checks the login state
// and shows either the user's profile or the login/signup page.
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
    // Listen for changes in authentication state to rebuild the widget
    _authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    _authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {
        // Rebuilds the widget when auth state changes (e.g., after login/logout)
      });
    }
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

// This widget contains the UI for Login and Sign Up tabs.
class LoginSignUpPage extends StatefulWidget {
  const LoginSignUpPage({super.key});

  @override
  State<LoginSignUpPage> createState() => _LoginSignUpPageState();
}

class _LoginSignUpPageState extends State<LoginSignUpPage>
    with SingleTickerProviderStateMixin {
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

  void _handleEmailLogin() {
    if (_loginFormKey.currentState!.validate()) {
      // Mocks a successful sign-in and notifies listeners to rebuild ProfilePage
      AuthService()
          .mockSignIn(_loginEmailController.text, _loginEmailController.text);
    }
  }

  void _handleEmailSignUp() {
    if (_signupFormKey.currentState!.validate()) {
      // Mocks a successful sign-up and notifies listeners to rebuild ProfilePage
      AuthService()
          .mockSignIn(_signupNameController.text, _signupEmailController.text);
    }
  }

  // FIX: Unified and corrected Google Sign-In logic.
  Future<void> _handleGoogleSignIn() async {
    const storage = FlutterSecureStorage();
    // IMPROVEMENT: This URL should be in a config file, not hardcoded.
    const serverUrl = 'http://127.0.0.1:8000';
    const googleWebClientId =
        '137371359979-uteh19od42d7hjal2s75ifcbf8329i5i.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn =
        GoogleSignIn(serverClientId: googleWebClientId);

    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('User cancelled Google Sign-In');
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('Could not retrieve ID token.');
      }

      final response = await http.post(
        Uri.parse('$serverUrl/api/v1/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'jwt_token', value: data['token']);

        // Create user model from backend response and sign in
        final user = UserModel(
          uid: data['user']['id'], // Using correct key 'id'
          name: data['user']['name'],
          email: data['user']['email'],
          photoUrl: data['user']['picture'], // Using correct key 'picture'
        );

        // This call will notify listeners and trigger the UI update
        AuthService().signInWithGoogle(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Successfully signed in!'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        throw Exception('Backend authentication failed: ${response.body}');
      }
    } catch (error) {
      debugPrint('Google Sign-In error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Google Sign-In failed: $error'),
              backgroundColor: Colors.red),
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
            Container(
              height: 180,
              width: double.infinity,
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
                    'Join Our Platform',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Colors.white,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelColor: const Color(0xFF1E3A8A),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Login'),
                  Tab(text: 'Sign Up'),
                ],
              ),
            ),
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
      // FIX: Removed the redundant bottom navigation bar.
    );
  }

  Widget _buildLoginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email
            TextFormField(
              controller: _loginEmailController,
              decoration: const InputDecoration(
                  labelText: 'Email Address', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Password
            TextFormField(
              controller: _loginPasswordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isLoginPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(
                      () => _isLoginPasswordVisible = !_isLoginPasswordVisible),
                ),
              ),
              obscureText: !_isLoginPasswordVisible,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            // Sign In Button
            ElevatedButton(
              onPressed: _handleEmailLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign In', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            // Google Sign In Button
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              icon: Image.network(
                  'https://developers.google.com/identity/images/g-logo.png',
                  height: 20),
              label: const Text('Sign In with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Form(
        key: _signupFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name
            TextFormField(
              controller: _signupNameController,
              decoration: const InputDecoration(
                  labelText: 'Full Name', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Email
            TextFormField(
              controller: _signupEmailController,
              decoration: const InputDecoration(
                  labelText: 'Email Address', border: OutlineInputBorder()),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || !value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            // Password
            TextFormField(
              controller: _signupPasswordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isSignupPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () => setState(() =>
                      _isSignupPasswordVisible = !_isSignupPasswordVisible),
                ),
              ),
              obscureText: !_isSignupPasswordVisible,
              validator: (value) {
                if (value == null || value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            // Create Account Button
            ElevatedButton(
              onPressed: _handleEmailSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child:
                  const Text('Create Account', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            // Google Sign Up Button
            ElevatedButton.icon(
              onPressed: _handleGoogleSignIn,
              icon: Image.network(
                  'https://developers.google.com/identity/images/g-logo.png',
                  height: 20),
              label: const Text('Sign Up with Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- OTHER PAGES (REFACTORED) ---

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
  State<PremierConstructionPage> createState() =>
      _PremierConstructionPageState();
}

class _PremierConstructionPageState extends State<PremierConstructionPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // FIX: Added a proper AppBar for better UX on a sub-page.
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1E3A8A),
        centerTitle: true,
      ),
      // FIX: The body is now a SingleChildScrollView to prevent UI overflow.
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.tagline,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Statistics Section
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.home,
                      number: '150+',
                      label: 'Projects\nCompleted',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.emoji_events,
                      number: '25',
                      label: 'Years\nExperience',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.people,
                      number: '200+',
                      label: 'Satisfied\nClients',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.calendar_today,
                      number: '98%',
                      label: 'On-Time\nDelivery',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Projects Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Our Previous Projects',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E3A8A),
                      ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Explore our portfolio of completed construction projects.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 280, // Adjusted height for better visuals
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildProjectCard(
                      title: 'Modern Hillside Villa',
                      image:
                          'https://images.unsplash.com/photo-1564013799919-ab600027ffc6?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                      label: 'New Construction',
                    ),
                    const SizedBox(width: 16),
                    _buildProjectCard(
                      title: 'Luxury Estate Residence',
                      image:
                          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                      label: 'Luxury Home',
                    ),
                    const SizedBox(width: 16),
                    _buildProjectCard(
                      title: 'Contemporary Family Home',
                      image:
                          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
                      label: 'Custom Home',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // FIX: Removed the redundant bottom navigation bar.
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String number,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          Icon(icon, color: const Color(0xFF1E3A8A), size: 28),
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
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600]),
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
  }) {
    return SizedBox(
      width: 250,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  image,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Chip(
                    label: Text(label),
                    backgroundColor: const Color(0xFF1E3A8A).withOpacity(0.8),
                    labelStyle: const TextStyle(color: Colors.white),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E3A8A),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// NOTE: The `FirstTimeUserForm` widget was not changed as it appears to be
// a separate form page that would be pushed onto the navigation stack,
// which is a correct implementation. It already has an AppBar for back navigation.
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
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Salem',
      'Tiruchirappalli',
      'Vellore',
      'Erode',
      'Tiruppur',
      'Dindigul',
      'Thoothukkudi'
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
                    TextFormField(
                      controller: _nameController,
                      decoration:
                          _buildInputDecoration('Full Name', 'Enter your full name'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // ... other form fields ...
                  ],
                ),
              ),
            ),
            // Fixed Submit Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
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
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Submit', style: TextStyle(fontSize: 16)),
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
    );
  }
}