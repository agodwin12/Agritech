import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserProductDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final Map<String, dynamic> userData;
  final String token;

  const UserProductDetailsScreen({
    Key? key,
    required this.product,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<dynamic> imageUrls = [];

    final imagesField = product['images'];

    if (imagesField is String) {
      try {
        imageUrls = jsonDecode(imagesField);
      } catch (e) {
        print('Failed to decode images: $e');
        imageUrls = [];
      }
    } else if (imagesField is List) {
      imageUrls = imagesField;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          product['name'] ?? 'Product Details',
          style: GoogleFonts.poppins(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              if (imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    'http://10.0.2.2:3000${imageUrls[0]}',
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.broken_image, size: 50),
                  ),
                )
              else
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                      child: Icon(Icons.image_not_supported, size: 50)),
                ),

              const SizedBox(height: 20),

              // Product Name
              Text(
                product['name'] ?? 'No Name',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Price
              Text(
                'Price: ${product['price']} XAF',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),

              const SizedBox(height: 8),

              // Stock
              Text(
                'Available Quantity: ${product['stock_quantity']}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                'Description',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product['description'] ?? 'No description available.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
