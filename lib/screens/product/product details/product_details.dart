import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2E7D32);
    final Color lightGreen = const Color(0xFF4CAF50);

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name'] ?? 'Product Details'),
        backgroundColor: primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product['image'],
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 100),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product['name'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '\XAF ${product['price']}',
              style: TextStyle(fontSize: 20, color: primaryGreen),
            ),
            const SizedBox(height: 10),
            Text(
              'Seller: ${product['seller']}\nMarket: ${product['market']}',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Text(
              product['description'] ?? 'No description available.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final phone = product['seller_phone'];
                  final Uri url = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not launch dialer')),
                    );
                  }
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call Seller'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: lightGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
