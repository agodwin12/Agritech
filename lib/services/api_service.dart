import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // Add this import for MediaType
import '../models/category.dart';
import '../models/product.dart';
import '../models/review.dart';
import '../models/sub_category.dart';
import '../models/cart_item.dart';
import '../models/user_profile.dart';

class ApiService {
  final String baseUrl;
  String _token; // ✅ Mutable private token

  ApiService({required this.baseUrl, required String token}) : _token = token;

  // ✅ Setter to update token after login
  set token(String newToken) {
    _token = newToken;
  }

  // ✅ Getter if needed
  String get token => _token;


  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }
  // Example: Get categories
  Future<List<Category>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token', // Use updated token
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories: ${response.body}');
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

    print('🧾 Response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      return CartItem.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add item to cart: ${response.body}');
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
  Future<void> createOrder({
    required String shippingAddress,
    required String shippingMethod,
    required String paymentMethod,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'shipping_address': shippingAddress,
        'shipping_method': shippingMethod,
        'payment_method': paymentMethod,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201) {
      print('❌ Status: ${response.statusCode}');
      print('❌ Body: ${response.body}');

      try {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to place order');
      } catch (_) {
        throw Exception('Unexpected response: ${response.body}');
      }
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

  Future<List<Review>> getReviews(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/reviews/$productId'),
      headers: _headers(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Review.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  Future<void> submitReview(int productId, String comment, double rating) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/products/$productId/reviews'),  // Changed endpoint to match backend
      headers: _headers(),
      body: jsonEncode({
        'comment': comment,
        'rating': rating,

      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to submit review: ${response.body}');
    }
  }


  Future<UserProfile> getUserProfile(int userId) async {
    try {
      // Debug print to track the request
      print('Getting user profile for userId: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/profile'),
        headers: _headers(),
      );

      // Debug print the response
      print('getUserProfile response code: ${response.statusCode}');
      print('getUserProfile response body: ${response.body}');

      if (response.statusCode == 200) {
        return UserProfile.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      print('Error in getUserProfile: $e');
      throw Exception('Error fetching user profile: $e');
    }
  }


  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/${endpoint.replaceAll(RegExp(r'^/+'), '')}');
    final response = await http.get(url, headers: _headers());

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('GET request failed: ${response.body}');
    }
  }

  Future<void> put(String endpoint, {required Map<String, dynamic> body}) async {
    final url = Uri.parse('${baseUrl.replaceAll(RegExp(r'/+$'), '')}/${endpoint.replaceAll(RegExp(r'^/+'), '')}');
    final response = await http.put(url, headers: _headers(), body: json.encode(body));

    if (response.statusCode != 200) {
      throw Exception('PUT request failed: ${response.statusCode} ${response.body}');
    }
  }



}