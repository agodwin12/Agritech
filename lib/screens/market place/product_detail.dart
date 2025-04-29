// lib/screens/market_place/product_detail.dart
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/api_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final Map<String, dynamic> userData;
  final String token;

  const ProductDetailScreen({
    Key? key,
    required this.productId,
    required this.userData,
    required this.token,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late ApiService _apiService;
  Product? _product;
  bool _isLoading = true;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      baseUrl: 'http://10.0.2.2:3000', // Replace with your actual API URL
      token: widget.token,
    );
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final product = await _apiService.getProductDetails(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading product details: $e')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text(_isLoading ? 'Product Details' : _product!.name),
    ),
    body: _isLoading
    ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    // Product Images
    AspectRatio(
    aspectRatio: 1,
    child: _product!.images != null && _product!.images!.isNotEmpty
    ? PageView.builder(
    itemCount: _product!.images!.length,
    itemBuilder: (context, index) {
    return Image.network(
    _product!.images![index],
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
    return Container(
    color: Colors.grey[300],
    child: const Center(
    child: Icon(Icons.image_not_supported, size: 50),
    ),
    );
    },
    );
    },
    )
        : Container(
    color: Colors.grey[300],
    child: const Center(
    child: Icon(Icons.image, size: 50),
    ),
    ),
    ),

    // Product Information
    Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
    Expanded(
    child: Text(
    _product!.name,
    style: const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    Text(
    '\XAF${_product!.price.toStringAsFixed(2)}',
    style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).primaryColor,
    ),
    ),
    ],
    ),

    const SizedBox(height: 16),

    // Categories
    Wrap(
    spacing: 8.0,
    children: [
    Chip(
    label: Text(_product!.categoryName ?? 'Unknown Category'),
    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
    ),
    Chip(
    label: Text(_product!.subCategoryName ?? 'Unknown Subcategory'),
    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
    ),
    ],
    ),

    const SizedBox(height: 16),

    // Stock Information
    Row(
    children: [
    Icon(
    _product!.stockQuantity > 0 ? Icons.check_circle : Icons.cancel,
    color: _product!.stockQuantity > 0 ? Colors.green : Colors.red,
    ),
    const SizedBox(width: 8),
    Text(
    _product!.stockQuantity > 0
    ? 'In Stock (${_product!.stockQuantity} available)'
        : 'Out of Stock',
    style: TextStyle(
    color: _product!.stockQuantity > 0 ? Colors.green : Colors.red,
    fontWeight: FontWeight.bold,
    ),
    ),
    ],
    ),

      const SizedBox(height: 24),

      // Description
      if (_product!.description != null && _product!.description!.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _product!.description!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),

      // Quantity Selector
      Row(
        children: [
          const Text(
            'Quantity:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                // Decrease Button
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _quantity > 1
                      ? () {
                    setState(() {
                      _quantity--;
                    });
                  }
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
                // Quantity Display
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _quantity.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                // Increase Button
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _quantity < _product!.stockQuantity
                      ? () {
                    setState(() {
                      _quantity++;
                    });
                  }
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
              ],
            ),
          ),
        ],
      ),

      const SizedBox(height: 32),

      // Add to Cart Button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _product!.stockQuantity > 0
              ? () {
            _addToCart();
          }
              : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _product!.stockQuantity > 0
                ? 'Add to Cart - \XAF ${(_product!.price * _quantity).toStringAsFixed(2)}'
                : 'Out of Stock',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
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

  Future<void> _addToCart() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Adding to cart..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Implement your addToCart API call here
      // For example:
      // await _apiService.addToCart(_product!.id, _quantity);

      // For now we'll just simulate a delay
      await Future.delayed(const Duration(seconds: 1));

      // Close the loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_product!.name} added to cart!'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              Navigator.pop(context); // Return to previous screen
              // Navigate to cart screen
              // You'd implement this based on your navigation structure
            },
          ),
        ),
      );
    } catch (e) {
      // Close the loading dialog
      Navigator.pop(context);

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding to cart: $e')),
      );
    }
  }
}