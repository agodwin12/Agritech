import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this import for MediaType
import '../models/category.dart';
import '../models/product.dart';
import '../models/sub_category.dart';
import '../models/cart_item.dart';

class ApiService {
  final String baseUrl;
  final String token;

  ApiService({required this.baseUrl, required this.token});

  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<SubCategory>> getSubCategories(int categoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/subcategories/category/$categoryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => SubCategory.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subcategories');
    }
  }

  Future<List<Product>> getAllProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> getFeaturedProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products/featured'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load featured products');
    }
  }

  Future<List<Product>> getProductsByCategory(int categoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products/category/$categoryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products by category');
    }
  }

  Future<List<Product>> getProductsBySubCategory(int subCategoryId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products/subcategory/$subCategoryId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products by subcategory');
    }
  }

  Future<Product> getProductDetails(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/products/$productId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load product details');
    }
  }

  // Cart methods
  Future<List<CartItem>> getUserCart() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/cart'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => CartItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cart');
    }
  }

  Future<CartItem> addToCart(int productId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/cart/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'productId': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200) {
      return CartItem.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add item to cart');
    }
  }

  Future<CartItem> updateCartItem(int cartItemId, int quantity) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/cart/$cartItemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200) {
      return CartItem.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update cart item');
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/cart/$cartItemId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to remove item from cart');
    }
  }

  Future<void> clearCart() async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/cart'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to clear cart');
    }
  }

  // Order methods
  Future<Map<String, dynamic>> createOrder(String shippingAddress, String shippingMethod, String paymentMethod, String? notes) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'shipping_address': shippingAddress,
        'shipping_method': shippingMethod,
        'payment_method': paymentMethod,
        'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create order');
    }
  }

  Future<List<dynamic>> getUserOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/$orderId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load order details');
    }
  }

  Future<dynamic> createProduct(Map<String, dynamic> productData, List<File> images) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/products'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add product data
      productData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // Add product images
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileExtension = file.path.split('.').last.toLowerCase();
        final contentType = fileExtension == 'png'
            ? 'image/png'
            : fileExtension == 'jpg' || fileExtension == 'jpeg'
            ? 'image/jpeg'
            : 'application/octet-stream';

        final stream = http.ByteStream(file.openRead());
        final length = await file.length();

        final multipartFile = http.MultipartFile(
          'images',  // Field name (should match backend expectation)
          stream,
          length,
          filename: 'image_$i.$fileExtension',
          contentType: MediaType.parse(contentType),
        );

        request.files.add(multipartFile);
      }

      // Send the request
      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        // Successfully created
        return json.decode(responseString);
      } else {
        throw Exception('Failed to create product: ${response.statusCode}, $responseString');
      }
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/orders/$orderId/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to cancel order');
    }
  }
}