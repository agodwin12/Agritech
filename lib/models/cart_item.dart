// lib/models/cart_item.dart
import 'dart:convert';

import 'product.dart';

class CartItem {
  final int id;
  final int quantity;
  final Product product;
  final int userId;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CartItem({
    required this.id,
    required this.quantity,
    required this.product,
    required this.userId,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Parse Product
    final productJson = json['Product'];
    Product product;

    if (productJson != null) {
      // Fix: Handle images safely (could be List or JSON string)
      List<String>? imagesList;
      try {
        if (productJson['images'] is List) {
          imagesList = List<String>.from(productJson['images']);
        } else if (productJson['images'] is String) {
          imagesList = List<String>.from(jsonDecode(productJson['images']));
        }
      } catch (e) {
        print('❌ Error parsing product images: $e');
      }

      product = Product(
        id: productJson['id'] ?? 0,
        name: productJson['name'] ?? 'Unknown',
        price: (productJson['price'] is String)
            ? double.tryParse(productJson['price']) ?? 0.0
            : (productJson['price'] ?? 0.0),
        stockQuantity: productJson['stock_quantity'] ?? 0,
        description: productJson['description'],
        categoryName: productJson['category_name'],
        subCategoryName: productJson['sub_category_name'],
        images: imagesList,
        isNew: productJson['is_new'] ?? false,
        userId: productJson['user_id'] ?? productJson['UserId'],
        sellerName: productJson['seller_name'],
        sellerImage: productJson['seller_image'],
        sellerRating: (productJson['seller_rating'] is String)
            ? double.tryParse(productJson['seller_rating'])
            : productJson['seller_rating'],
      );
    } else {
      // Fallback in case Product is null
      product = Product(
        id: 0,
        name: 'Unknown',
        price: 0.0,
        stockQuantity: 0,
        description: null,
        categoryName: null,
        subCategoryName: null,
        images: null,
        isNew: false,
        userId: null,
        sellerName: null,
        sellerImage: null,
        sellerRating: null,
      );
    }

    return CartItem(
      id: json['id'] ?? 0,
      quantity: json['quantity'] ?? 1,
      product: product,
      userId: json['UserId'] ?? 0,
      productId: json['ProductId'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }}