// lib/models/cart_item.dart
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
    return CartItem(
      id: json['id'] ?? 0,
      quantity: json['quantity'] ?? 1,
      product: json['Product'] != null
          ? Product.fromJson(json['Product'])
          : Product(
        id: 0,
        name: 'Unknown',
        price: 0.0,
        stockQuantity: 0,
        isFeatured: false,
        categoryId: 0,
        subCategoryId: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      userId: json['UserId'] ?? 0,
      productId: json['ProductId'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}