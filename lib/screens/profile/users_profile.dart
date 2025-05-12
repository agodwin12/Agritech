// lib/screens/user/user_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product.dart';
import '../../models/user_profile.dart';
import '../../services/api_service.dart';
import '../market place/product_detail.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  final String token;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late ApiService _apiService;
  UserProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      baseUrl: 'http://10.0.2.2:3000',
      token: widget.token,
    );
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProfile = await _apiService.getUserProfile(widget.userId);
      setState(() {
        _userProfile = userProfile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final backgroundColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _isLoading || _userProfile == null ? 'User Profile' : _userProfile!.fullName,          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              Card(
                color: cardColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Image
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        backgroundImage: _userProfile?.profileImage != null
                            ? NetworkImage(_userProfile!.profileImage!)
                            : null,
                        child: _userProfile?.profileImage == null
                            ? Icon(
                          Icons.person,
                          size: 50,
                          color: primaryColor,
                        )
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        _userProfile!.fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            _userProfile!.averageRating.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Bio
                      if (_userProfile?.bio != null && _userProfile!.bio!.isNotEmpty) ...[
                        Text(
                          _userProfile!.bio!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Social Media Links
                      if (_userProfile?.facebook != null ||
                          _userProfile?.instagram != null ||
                          _userProfile?.twitter != null ||
                          _userProfile?.tiktok != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_userProfile?.facebook != null && _userProfile!.facebook!.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.facebook, color: primaryColor),
                                onPressed: () {
                                  // Open Facebook URL
                                },
                              ),
                            if (_userProfile?.instagram != null && _userProfile!.instagram!.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.camera_alt, color: primaryColor),
                                onPressed: () {
                                  // Open Instagram URL
                                },
                              ),
                            if (_userProfile?.twitter != null && _userProfile!.twitter!.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.flutter_dash, color: primaryColor),
                                onPressed: () {
                                  // Open Twitter URL
                                },
                              ),
                            if (_userProfile?.tiktok != null && _userProfile!.tiktok!.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.music_note, color: primaryColor),
                                onPressed: () {
                                  // Open TikTok URL
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Member Since
                      Text(
                        'Member since ${_formatDate(_userProfile!.createdAt)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Products Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Products by ${_userProfile!.fullName}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    '${_userProfile!.products?.length ?? 0} products',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Products Grid
              if (_userProfile?.products == null || _userProfile!.products!.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No products yet',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _userProfile!.products!.length,
                  itemBuilder: (context, index) {
                    final product = _userProfile!.products![index];
                    return _buildProductCard(product, cardColor, primaryColor);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, Color cardColor, Color primaryColor) {
    return Card(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                productId: product.id,
                userData: {},
                token: widget.token,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: product.images != null && product.images!.isNotEmpty
                    ? Image.network(
                  product.images![0],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey),
                      ),
                    );
                  },
                )
                    : Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, size: 40, color: Colors.grey),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Product Price
                  Text(
                    '\XAF${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Stock Status
                  Text(
                    product.stockQuantity > 0 ? 'In Stock' : 'Out of Stock',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: product.stockQuantity > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year}';
  }
}