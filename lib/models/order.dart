// lib/models/order.dart
import 'package:flutter/foundation.dart';

class Order {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String shippingAddress;
  final String? shippingMethod;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int userId;
  final List<OrderItem>? orderItems;

  Order({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.shippingAddress,
    this.shippingMethod,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.orderItems,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem>? items;
    if (json['OrderItems'] != null) {
      items = List<OrderItem>.from(
        json['OrderItems'].map((x) => OrderItem.fromJson(x)),
      );
    }

    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      paymentStatus: json['payment_status'],
      shippingAddress: json['shipping_address'],
      shippingMethod: json['shipping_method'],
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      userId: json['UserId'],
      orderItems: items,
    );
  }
}

class OrderItem {
  final int id;
  final int quantity;
  final double price;
  final double subtotal;
  final int orderId;
  final int productId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? product;

  OrderItem({
    required this.id,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.orderId,
    required this.productId,
    required this.createdAt,
    required this.updatedAt,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      quantity: json['quantity'],
      price: double.parse(json['price'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      orderId: json['OrderId'],
      productId: json['ProductId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      product: json['Product'],
    );
  }
}