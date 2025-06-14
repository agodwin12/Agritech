// lib/services/cart_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/ebook_model.dart';

class CartItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String? coverImage;
  final String? categoryName;
  final DateTime addedAt;
  final Ebook originalEbook;

  CartItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    this.coverImage,
    this.categoryName,
    required this.addedAt,
    required this.originalEbook,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'coverImage': coverImage,
      'categoryName': categoryName,
      'addedAt': addedAt.toIso8601String(),
      'originalEbook': originalEbook.toJson(), // Assuming your Ebook model has toJson
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      coverImage: json['coverImage'],
      categoryName: json['categoryName'],
      addedAt: DateTime.parse(json['addedAt']),
      originalEbook: Ebook.fromJson(json['originalEbook']), // Assuming your Ebook model has fromJson
    );
  }
}

class CartService {
  static const String _cartKey = 'ebook_cart';
  static CartService? _instance;
  static CartService get instance => _instance ??= CartService._();

  CartService._();

  List<CartItem> _cartItems = [];
  List<Function()> _listeners = [];

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get itemCount => _cartItems.length;
  double get totalPrice => _cartItems.fold(0.0, (sum, item) => sum + item.price);

  // Add listener for cart changes
  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  // Load cart from storage
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartKey);

      if (cartJson != null) {
        final List<dynamic> cartList = json.decode(cartJson);
        _cartItems = cartList.map((item) => CartItem.fromJson(item)).toList();
        _notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  // Save cart to storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(_cartItems.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Add item to cart
  Future<bool> addToCart(Ebook ebook) async {
    try {
      // Check if item already exists
      if (isInCart(ebook.id.toString())) {
        return false; // Item already in cart
      }

      final cartItem = CartItem(
        id: ebook.id.toString(), // Convert int to string
        title: ebook.title,
        description: ebook.description,
        price: double.tryParse(ebook.price.toString()) ?? 0.0, // Convert string to double
        coverImage: ebook.coverImage,
        categoryName: ebook.categoryName,
        addedAt: DateTime.now(),
        originalEbook: ebook,
      );

      _cartItems.add(cartItem);
      await _saveCart();
      _notifyListeners();
      return true;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeFromCart(String ebookId) async {
    try {
      final initialLength = _cartItems.length;
      _cartItems.removeWhere((item) => item.id == ebookId);

      if (_cartItems.length < initialLength) {
        await _saveCart();
        _notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing from cart: $e');
      return false;
    }
  }

  // Check if item is in cart
  bool isInCart(String ebookId) {
    return _cartItems.any((item) => item.id == ebookId);
  }

  // Clear entire cart
  Future<void> clearCart() async {
    try {
      _cartItems.clear();
      await _saveCart();
      _notifyListeners();
    } catch (e) {
      print('Error clearing cart: $e');
    }
  }

  // Get cart item by ID
  CartItem? getCartItem(String ebookId) {
    try {
      return _cartItems.firstWhere((item) => item.id == ebookId);
    } catch (e) {
      return null;
    }
  }
}