// lib/screens/market_place/market.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../navigation bar/navigation_bar.dart';
import 'manage_products_screen.dart';
import 'product_detail.dart';
import 'cart_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const MarketplaceScreen({
    Key? key,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late ApiService _apiService;
  List<Category> _categories = [];
  List<Product> _products = [];
  List<Product> _featuredProducts = [];
  bool _isLoading = true;
  int? _selectedCategoryId;
  int? _selectedSubCategoryId;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Custom theme colors
  final Color _primaryGreen = const Color(0xFF2E7D32); // Deep forest green
  final Color _lightGreen = const Color(0xFFAED581);   // Light leaf green
  final Color _accentGreen = const Color(0xFF66BB6A); // Medium green
  final Color _highlightColor = const Color(0xFFFFD54F); // Golden yellow for highlights
  final Color _darkGreen = const Color(0xFF1B5E20);    // Dark forest green

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      baseUrl: 'http://10.0.2.2:3000', // Replace with your actual API URL
      token: widget.token,
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _apiService.getCategories();
      final products = await _apiService.getAllProducts();
      final featuredProducts = await _apiService.getFeaturedProducts();

      setState(() {
        _categories = categories;
        _products = products;
        _featuredProducts = featuredProducts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading marketplace data: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _filterByCategory(int categoryId) async {
    setState(() {
      _isLoading = true;
      _selectedCategoryId = categoryId;
      _selectedSubCategoryId = null;
    });

    try {
      final products = await _apiService.getProductsByCategory(categoryId);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error filtering by category: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _filterBySubCategory(int subCategoryId) async {
    setState(() {
      _isLoading = true;
      _selectedSubCategoryId = subCategoryId;
    });

    try {
      final products = await _apiService.getProductsBySubCategory(subCategoryId);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error filtering by subcategory: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedSubCategoryId = null;
      _searchQuery = '';
      _searchController.clear();
    });
    _loadData();
  }

  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) {
      return _products;
    }
    return _products.where((product) =>
    product.name.toLowerCase().contains(_searchQuery) ||
        (product.description ?? '').toLowerCase().contains(_searchQuery)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.grey[800]!;
    final backgroundColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final cardColor = isDarkMode ? Colors.grey[850]! : Colors.white;

    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;

    // Calculate number of grid columns based on screen width
    int gridColumns = screenSize.width < 600 ? 2 : (screenSize.width < 900 ? 3 : 4);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_darkGreen, _primaryGreen],
            ),
          ),
        ),
        title: Text(
          'Farm Market',
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(
                    userData: widget.userData,
                    token: widget.token,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          image: DecorationImage(
            image: const AssetImage('assets/subtle_farm_pattern.jpg'),
            opacity: 0.05,
            repeat: ImageRepeat.repeat,
          ),
        ),
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: _primaryGreen,
            strokeWidth: 3,
          ),
        )
            : CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar Space
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),

            // Search Bar with responsive padding
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.05,
                  vertical: 16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for agricultural products...',
                      hintStyle: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      prefixIcon: Icon(Icons.search, color: _primaryGreen),
                      filled: true,
                      fillColor: cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: _primaryGreen),
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts('');
                        },
                      )
                          : null,
                    ),
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      color: textColor,
                    ),
                    onChanged: _searchProducts,
                  ),
                ),
              ),
            ),

            // Category Filter with responsive height
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                height: screenSize.height * 0.07,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
                  itemCount: _categories.length + 1, // +1 for "All" option
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            'All Products',
                            style: GoogleFonts.raleway(
                              fontWeight: FontWeight.bold,
                              color: _selectedCategoryId == null ? Colors.white : textColor,
                            ),
                          ),
                          selected: _selectedCategoryId == null,
                          selectedColor: _primaryGreen,
                          backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                            side: BorderSide(
                              color: _selectedCategoryId == null ? _primaryGreen : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          elevation: 0,
                          onSelected: (selected) {
                            if (selected) {
                              _resetFilters();
                            }
                          },
                        ),
                      );
                    }

                    final category = _categories[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(
                          category.name,
                          style: GoogleFonts.raleway(
                            fontWeight: FontWeight.bold,
                            color: _selectedCategoryId == category.id ? Colors.white : textColor,
                          ),
                        ),
                        selected: _selectedCategoryId == category.id,
                        selectedColor: _primaryGreen,
                        backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: BorderSide(
                            color: _selectedCategoryId == category.id ? _primaryGreen : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                        onSelected: (selected) {
                          if (selected) {
                            _filterByCategory(category.id);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // SubCategory Filter with responsive height
            if (_selectedCategoryId != null)
              SliverToBoxAdapter(
                child: Container(
                  height: screenSize.height * 0.06,
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
                    itemCount: _categories
                        .firstWhere((cat) => cat.id == _selectedCategoryId)
                        .subCategories!.length,
                    itemBuilder: (context, index) {
                      final subCategory = _categories
                          .firstWhere((cat) => cat.id == _selectedCategoryId)
                          .subCategories![index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Text(
                            subCategory.name,
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.w500,
                              color: _selectedSubCategoryId == subCategory.id ? Colors.white : textColor,
                            ),
                          ),
                          selected: _selectedSubCategoryId == subCategory.id,
                          selectedColor: _accentGreen,
                          backgroundColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.7) : Colors.grey[100],
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              _filterBySubCategory(subCategory.id);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Featured Products Section with responsive height and width
            if (_selectedCategoryId == null && _searchQuery.isEmpty && _featuredProducts.isNotEmpty)
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          screenSize.width * 0.05,
                          16,
                          screenSize.width * 0.05,
                          8
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: _highlightColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Featured Products',
                            style: GoogleFonts.raleway(
                              fontSize: screenSize.width < 600 ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: screenSize.height * 0.28,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
                        itemCount: _featuredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _featuredProducts[index];
                          return FeaturedProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductDetailScreen(
                                    productId: product.id,
                                    userData: widget.userData,
                                    token: widget.token,
                                  ),
                                ),
                              );
                            },
                            primaryColor: _primaryGreen,
                            accentColor: _highlightColor,
                            textColor: textColor,
                            cardColor: cardColor,
                            isDarkMode: isDarkMode,
                            screenWidth: screenSize.width,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Available Products Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    screenSize.width * 0.05,
                    8,
                    screenSize.width * 0.05,
                    8
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      color: _primaryGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategoryId != null || _searchQuery.isNotEmpty
                          ? 'Results (${_filteredProducts.length})'
                          : 'Available Products',
                      style: GoogleFonts.raleway(
                        fontSize: screenSize.width < 600 ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Grid with responsive layout
            _filteredProducts.isEmpty
                ? SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No products found',
                      style: GoogleFonts.raleway(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try changing your search or filters',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            )
                : SliverPadding(
              padding: EdgeInsets.all(screenSize.width * 0.04),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns,
                  childAspectRatio: 0.75, // Adjusted for better responsiveness
                  crossAxisSpacing: screenSize.width * 0.03,
                  mainAxisSpacing: screenSize.width * 0.03,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final product = _filteredProducts[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              productId: product.id,
                              userData: widget.userData,
                              token: widget.token,
                            ),
                          ),
                        );
                      },
                      primaryColor: _primaryGreen,
                      accentColor: _accentGreen,
                      textColor: textColor,
                      cardColor: cardColor,
                      isDarkMode: isDarkMode,
                    );
                  },
                  childCount: _filteredProducts.length,
                ),
              ),
            ),

            // Bottom padding for better scroll experience
            SliverToBoxAdapter(
              child: SizedBox(height: screenSize.height * 0.1),
            ),
          ],
        ),
      ),
      // Floating action button with updated design
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductScreen(
                userData: widget.userData,
                token: widget.token,
                categories: _categories,
                onProductAdded: () {
                  _loadData();
                },
              ),
            ),
          );
        },
        backgroundColor: _primaryGreen,
        elevation: 4,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text(
          'Sell Product',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      bottomNavigationBar: FarmConnectNavBar(
        isDarkMode: isDarkMode,
        darkColor: _darkGreen,
        primaryColor: _primaryGreen,
        textColor: textColor,
        currentIndex: 1, // Market tab
        userData: widget.userData,
        token: widget.token,
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Color cardColor;
  final bool isDarkMode;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.cardColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image - removed quality indicator
              AspectRatio(
                aspectRatio: 1,
                child: Hero(
                  tag: 'product-${product.id}',
                  child: product.images != null && product.images!.isNotEmpty
                      ? Image.network(
                    product.images!.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 30),
                        ),
                      );
                    },
                  )
                      : Container(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.eco_outlined,
                        size: 40,
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),

              // Product Info with enhanced styling
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.raleway(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 12,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  product.categoryName ?? 'Farm Product',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\XAF${product.price.toStringAsFixed(2)}',
                            style: GoogleFonts.lato(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.add_shopping_cart_outlined,
                              color: primaryColor,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FeaturedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Color cardColor;
  final bool isDarkMode;
  final double screenWidth;

  const FeaturedProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.cardColor,
    required this.isDarkMode,
    this.screenWidth = 360,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate responsive width based on screen size
    final double cardWidth = screenWidth < 600 ? 180 : (screenWidth < 900 ? 220 : 250);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image - removed rating indicators
              AspectRatio(
                aspectRatio: 1,
                child: Hero(
                  tag: 'featured-${product.id}',
                  child: product.images != null && product.images!.isNotEmpty
                      ? Image.network(
                    product.images!.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported),
                        ),
                      );
                    },
                  )
                      : Container(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.eco_outlined,
                        size: 50,
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
                      ),
                    ),
                  ),
                ),
              ),

              // Product info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.raleway(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.categoryName ?? 'Farm Product',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\XAF${product.price.toStringAsFixed(2)}',
                            style: GoogleFonts.lato(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.add_shopping_cart_outlined,
                              color: primaryColor,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}