import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:card_swiper/card_swiper.dart';
import '../../../models/product.dart';

class FeaturedProductHero extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color accentColor;
  final Color warningColor;
  final Color textColor;
  final bool isDarkMode;

  const FeaturedProductHero({
    Key? key,
    required this.product,
    required this.onTap,
    required this.primaryColor,
    required this.accentColor,
    required this.warningColor,
    required this.textColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final imageUrl = product.images != null && product.images!.isNotEmpty
        ? product.images!.first
        : 'https://via.placeholder.com/800x500?text=No+Image';

    return Container(
      height: size.height * 0.45,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          // Hero Image
          ClipRRect(
            borderRadius: BorderRadius.circular(0),
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.darken,
              child: Image.network(
                imageUrl,
                height: size.height * 0.45,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [const Color(0xFF2C3E50), const Color(0xFF1A1A2E)]
                          : [primaryColor.withOpacity(0.8), accentColor.withOpacity(0.9)],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.eco_outlined,
                      size: 80,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      // Featured badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: warningColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'FEATURED',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          product.categoryName ?? 'Farm Product',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // NEW badge if product is new
                      if (product.isNew ?? false)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Product Name
                  Text(
                    product.name,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      height: 1.2,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Product Description
                  Text(
                    product.description ?? 'Quality farm products from local producers',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 20),

                  // Price and Action Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Price',
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '\XAF${product.price.toStringAsFixed(0)}',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),

                      // Shop Now Button
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'SHOP NOW',
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 1,
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
    );
  }
}

// For multiple featured products, create a swiper carousel
class FeaturedProductsCarousel extends StatelessWidget {
  final List<Product> featuredProducts;
  final Function(Product) onProductTap;
  final Color primaryColor;
  final Color accentColor;
  final Color warningColor;
  final Color textColor;
  final bool isDarkMode;

  const FeaturedProductsCarousel({
    Key? key,
    required this.featuredProducts,
    required this.onProductTap,
    required this.primaryColor,
    required this.accentColor,
    required this.warningColor,
    required this.textColor,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (featuredProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.45,
      child: Swiper(
        itemBuilder: (context, index) {
          final product = featuredProducts[index];
          return FeaturedProductHero(
            product: product,
            onTap: () => onProductTap(product),
            primaryColor: primaryColor,
            accentColor: accentColor,
            warningColor: warningColor,
            textColor: textColor,
            isDarkMode: isDarkMode,
          );
        },
        itemCount: featuredProducts.length,
        pagination: SwiperPagination(
          builder: DotSwiperPaginationBuilder(
            activeColor: warningColor,
            color: Colors.white.withOpacity(0.5),
            size: 8.0,
            activeSize: 10.0,
          ),
        ),
        autoplay: true,
        autoplayDelay: 5000,
        duration: 800,
        control: const SwiperControl(size: 0), // Hide navigation arrows
      ),
    );
  }
}