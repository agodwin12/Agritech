import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class CartProvider with ChangeNotifier {
  ApiService _apiService;
  final List<CartItem> _cartItems = [];

  CartProvider(this._apiService);

  void updateApiService(ApiService newService) {
    _apiService = newService;
  }

  List<CartItem> get cartItems => _cartItems;

  Future<void> addProductToCart(Product product, {int quantity = 1}) async {
    try {
      CartItem item = await _apiService.addToCart(product.id, quantity);
      _cartItems.add(item);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}

