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
      id: json['id'],
      quantity: json['quantity'],
      product: Product.fromJson(json['Product']),
      userId: json['UserId'],
      productId: json['ProductId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}