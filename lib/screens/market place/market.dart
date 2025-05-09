// lib/screens/market_place/market.dart
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';
import '../../services/cart_provider.dart';
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

class _MarketplaceScreenState extends State<MarketplaceScreen> with SingleTickerProviderStateMixin {
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
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;

  // Modern theme colors
  final Color _primaryColor = const Color(0xFF16A085); // Teal
  final Color _secondaryColor = const Color(0xFF1ABC9C); // Light teal
  final Color _accentColor = const Color(0xFF3498DB); // Bright blue
  final Color _darkColor = const Color(0xFF2C3E50); // Dark slate
  final Color _warningColor = const Color(0xFFF39C12); // Orange
  final Color _neutralColor = const Color(0xFFECF0F1); // Light gray

  @override
  void initState() {
    super.initState();

    // Initialize animation controller first
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeInOut,
      ),
    );

    _animationController!.forward();

    // Initialize API service and load data
    _apiService = ApiService(
      baseUrl: 'http://10.0.2.2:3000',
      token: widget.token,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      _showErrorSnackBar('Error loading marketplace data: $e');
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
      _showErrorSnackBar('Error filtering by category: $e');
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
      _showErrorSnackBar('Error filtering by subcategory: $e');
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
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
    final textColor = isDarkMode ? Colors.white : _darkColor;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final bgPattern = isDarkMode ? 0.03 : 0.02;

    // Get screen size for responsive layout
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 600;
    final bool isMediumScreen = screenSize.width >= 600 && screenSize.width < 900;
    final bool isLargeScreen = screenSize.width >= 900;

    // Calculate grid columns based on screen width
    int gridColumns = isSmallScreen ? 2 : (isMediumScreen ? 3 : 4);

    // Calculate dynamic paddings
    final horizontalPadding = screenSize.width * (isSmallScreen ? 0.04 : 0.05);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: backgroundColor,
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: backgroundColor,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primaryColor, _secondaryColor],
              ),
            ),
          ),
          title: Text(
            'AGRO MARKET',
            style: GoogleFonts.montserrat(
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, size: 26),
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => CartScreen(
                          userData: widget.userData,
                          token: widget.token,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          var offsetAnimation = animation.drive(tween);

                          return SlideTransition(position: offsetAnimation, child: child);
                        },
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _warningColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '', // Replace with actual cart count
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: _isLoading
            ? _buildLoadingState(isDarkMode)
            : Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            image: DecorationImage(
              image: const AssetImage('assets/subtle_farm_pattern.jpg'),
              opacity: bgPattern,
              repeat: ImageRepeat.repeat,
            ),
          ),
          // Fixed Issue: Check if animation is initialized before using it
          child: _scaleAnimation == null
              ? const Center(child: CircularProgressIndicator())
              : AnimatedBuilder(
            animation: _scaleAnimation!,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation!.value,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // App Bar Space
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 100),
                    ),

                    // Greeting Section
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${widget.userData['name'] ?? 'Farmer'}!',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 20 : 24,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Find fresh farm products for your needs',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 13 : 15,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Search Bar with modern design
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 16,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isDarkMode ? [] : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search products...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 15,
                                color: isDarkMode ? Colors.grey[500] : Colors.grey[400],
                                fontWeight: FontWeight.w400,
                              ),
                              filled: true,
                              fillColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: _primaryColor,
                                size: 22,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: _primaryColor,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchProducts('');
                                  FocusScope.of(context).unfocus();
                                },
                              )
                                  : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: _primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                            ),
                            onChanged: _searchProducts,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (value) {
                              _searchProducts(value);
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                      ),
                    ),

                    // Category Filter with modern design
                    SliverToBoxAdapter(
                      child: Container(
                        height: screenSize.height * 0.06,
                        margin: const EdgeInsets.only(top: 8, bottom: 4),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                          itemCount: _categories.length + 1, // +1 for "All" option
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return _buildCategoryChip(
                                label: 'All Products',
                                isSelected: _selectedCategoryId == null,
                                onSelected: (selected) {
                                  if (selected) {
                                    _resetFilters();
                                  }
                                },
                                isDarkMode: isDarkMode,
                                textColor: textColor,
                              );
                            }

                            final category = _categories[index - 1];
                            return _buildCategoryChip(
                              label: category.name,
                              isSelected: _selectedCategoryId == category.id,
                              onSelected: (selected) {
                                if (selected) {
                                  _filterByCategory(category.id);
                                }
                              },
                              isDarkMode: isDarkMode,
                              textColor: textColor,
                            );
                          },
                        ),
                      ),
                    ),

                    // Subcategory Filter
                    if (_selectedCategoryId != null && _categories.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          height: screenSize.height * 0.05,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                            itemCount: _categories
                                .firstWhere(
                                    (cat) => cat.id == _selectedCategoryId,
                                orElse: () => Category(id: 0, name: '', subCategories: [])
                            )
                                .subCategories?.length ?? 0,
                            itemBuilder: (context, index) {
                              final selectedCategory = _categories.firstWhere(
                                      (cat) => cat.id == _selectedCategoryId,
                                  orElse: () => Category(id: 0, name: '', subCategories: [])
                              );

                              if (selectedCategory.subCategories == null ||
                                  selectedCategory.subCategories!.isEmpty ||
                                  index >= selectedCategory.subCategories!.length) {
                                return const SizedBox.shrink();
                              }

                              final subCategory = selectedCategory.subCategories![index];
                              return _buildSubcategoryChip(
                                label: subCategory.name,
                                isSelected: _selectedSubCategoryId == subCategory.id,
                                onSelected: (selected) {
                                  if (selected) {
                                    _filterBySubCategory(subCategory.id);
                                  }
                                },
                                isDarkMode: isDarkMode,
                                textColor: textColor,
                              );
                            },
                          ),
                        ),
                      ),

                    // Featured Products Section with swiper card
                    if (_selectedCategoryId == null && _searchQuery.isEmpty && _featuredProducts.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                16,
                                horizontalPadding,
                                12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _warningColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: _warningColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Featured Products',
                                    style: GoogleFonts.montserrat(
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: screenSize.height * 0.28,
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Swiper(
                                itemBuilder: (BuildContext context, int index) {
                                  final product = _featuredProducts[index];
                                  return FeaturedProductCard(
                                    product: product,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                              ProductDetailScreen(
                                                productId: product.id,
                                                userData: widget.userData,
                                                token: widget.token,
                                              ),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                    primaryColor: _primaryColor,
                                    accentColor: _accentColor,
                                    warningColor: _warningColor,
                                    textColor: textColor,
                                    isDarkMode: isDarkMode,
                                    screenWidth: screenSize.width,
                                  );
                                },
                                itemCount: _featuredProducts.length,
                                viewportFraction: isSmallScreen ? 0.8 : (isMediumScreen ? 0.6 : 0.4),
                                scale: 0.9,
                                layout: SwiperLayout.DEFAULT,
                                pagination: SwiperPagination(
                                  builder: DotSwiperPaginationBuilder(
                                    activeColor: _primaryColor,
                                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                    size: 6.0,
                                    activeSize: 8.0,
                                  ),
                                ),
                                control: const SwiperControl(size: 0), // Hide arrows
                                autoplay: true,
                                autoplayDelay: 5000,
                                duration: 800,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Available Products Section Title
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.eco_rounded,
                                color: _primaryColor,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCategoryId != null || _searchQuery.isNotEmpty
                                  ? 'Results (${_filteredProducts.length})'
                                  : 'Fresh Products',
                              style: GoogleFonts.montserrat(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Product Grid with modern cards
                    _filteredProducts.isEmpty
                        ? SliverFillRemaining(
                      child: _buildEmptyState(isDarkMode),
                    )
                        : SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        0,
                        horizontalPadding,
                        screenSize.height * 0.1,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridColumns,
                          childAspectRatio: 0.7,
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
                                  PageRouteBuilder(
                                    pageBuilder: (context, animation, secondaryAnimation) =>
                                        ProductDetailScreen(
                                          productId: product.id,
                                          userData: widget.userData,
                                          token: widget.token,
                                        ),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              primaryColor: _primaryColor,
                              accentColor: _accentColor,
                              textColor: textColor,
                              cardColor: cardColor,
                              isDarkMode: isDarkMode,
                            );
                          },
                          childCount: _filteredProducts.length,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => AddProductScreen(
                  userData: widget.userData,
                  token: widget.token,
                  categories: _categories,
                  onProductAdded: () {
                    _loadData();
                  },
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutQuint;

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          },
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: FarmConnectNavBar(
          isDarkMode: isDarkMode,
          darkColor: _darkColor,
          primaryColor: _primaryColor,
          textColor: textColor,
          currentIndex: 1, // Market tab
          userData: widget.userData,
          token: widget.token,
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    required bool isDarkMode,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
        selected: isSelected,
        selectedColor: _primaryColor,
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: 0,
        pressElevation: 0,
        onSelected: onSelected,
        avatar: isSelected ? Icon(
          Icons.check_circle_rounded,
          size: 16,
          color: Colors.white,
        ) : null,
        labelPadding: isSelected ? const EdgeInsets.only(left: 4, right: 8) : const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildSubcategoryChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    required bool isDarkMode,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: isSelected ? Colors.white : textColor.withOpacity(0.7),
          ),
        ),
        selected: isSelected,
        selectedColor: _accentColor,
        backgroundColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[200]!,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: 0,
        pressElevation: 0,
        onSelected: onSelected,
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 250,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar shimmer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            // Categories shimmer
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Featured products shimmer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Container(
                width: 180,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            // Products title shimmer
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Container(
                width: 160,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // Products grid shimmer
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 64,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No products found',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[300] : _darkColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Try changing your search or filters',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reset Filters'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDarkMode ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image with rounded corners and modern "out of stock" indicator
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: 'product-${product.id}',
                      child: product.images != null && product.images!.isNotEmpty
                          ? Image.network(
                        product.images!.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, size: 32),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Shimmer.fromColors(
                            baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                            highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
                            child: Container(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
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

                    // Favorite button overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                          boxShadow: isDarkMode ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_border_rounded,
                          color: Colors.red[400],
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Info with modern typography
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Product name and category
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textColor,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.categoryName ?? 'Farm Product',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Price and Add to Cart button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price with modern styling
                        Text(
                          '\XAF${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),

                        // Add to cart button
                        Container(
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isDarkMode ? [] : [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: InkWell(
                              onTap: () async {
                                // Check for null values that could cause type errors
                                if (product.id == null) {
                                  _showErrorSnackBar(context, 'Cannot add product: Missing product ID');
                                  return;
                                }

                                // Ensure price is a valid number
                                if (product.price == null) {
                                  _showErrorSnackBar(context, 'Cannot add product: Missing price');
                                  return;
                                }

                                try {
                                  final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                  await cartProvider.addProductToCart(product);

                                  _showSuccessSnackBar(
                                      context,
                                      '${product.name} added to cart'
                                  );
                                } catch (e) {
                                  print('🔥 Error adding product to cart: $e');
                                  _showErrorSnackBar(
                                      context,
                                      'Error adding to cart: ${e.toString().substring(0, Math.min(e.toString().length, 50))}'
                                  );
                                }
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(6.0),
                                child: Icon(
                                  Icons.add_shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
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
    );
  }

  // Helper method to show success messages
  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Helper method to show error messages
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class FeaturedProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color accentColor;
  final Color warningColor;
  final Color textColor;
  final bool isDarkMode;
  final double screenWidth;

  const FeaturedProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    required this.primaryColor,
    required this.accentColor,
    required this.warningColor,
    required this.textColor,
    required this.isDarkMode,
    this.screenWidth = 360,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [const Color(0xFF2C3E50), const Color(0xFF1A1A2E)]
                : [primaryColor.withOpacity(0.8), accentColor.withOpacity(0.9)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDarkMode
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: -5,
            )
          ]
              : [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: -5,
            )
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Opacity(
                opacity: 0.1,
                child: Image.network(
                  'https://i.imgur.com/8Ecyz1u.png', // A subtle pattern image
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox();
                  },
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card header with featured tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Featured tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: warningColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Featured',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          product.categoryName ?? 'Farm Product',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Product title
                  Text(
                    product.name,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Description snippet
                  Text(
                    product.description ?? 'Fresh farm products directly from local farmers',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 16),

                  // Price and call-to-action button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price display
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '\XAF${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ],
                      ),

                      // View Details button
                      TextButton.icon(
                        onPressed: onTap,
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text(
                          'View',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
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
}