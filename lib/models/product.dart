// lib/models/product.dart
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final String? categoryName;
  final String? subCategoryName;
  final List<String>? images;
  final bool? isNew;

  // Seller information - adapted to handle both naming conventions
  final int? userId;
  final String? sellerName;        // Original field name in your code
  final String? sellerFullName;    // Matches your user table's full_name
  final String? sellerImage;       // Original field name in your code
  final String? sellerProfileImage; // Matches your user table's profile_image
  final double? sellerRating;      // Original field name in your code
  final double? sellerAverageRating; // Alternative field name

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.categoryName,
    this.subCategoryName,
    this.images,
    this.isNew,
    this.userId,
    this.sellerName,
    this.sellerFullName,
    this.sellerImage,
    this.sellerProfileImage,
    this.sellerRating,
    this.sellerAverageRating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Debug print raw JSON
    print('Raw product JSON: $json');

    List<String>? imagesList;
    if (json['images'] != null) {
      imagesList = List<String>.from(json['images']);
    }

    // More robust parsing for price
    double parsePrice(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          print('Error parsing price: $value');
          return 0.0;
        }
      }
      return 0.0;
    }

    // More robust parsing for stockQuantity
    int parseStockQuantity(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('Error parsing stock quantity: $value');
          return 0;
        }
      }
      return 0;
    }

    // More robust parsing for isNew
    bool? parseIsNew(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        final lowercaseValue = value.toLowerCase().trim();
        if (lowercaseValue == 'true' || lowercaseValue == '1' || lowercaseValue == 'yes') {
          return true;
        }
        if (lowercaseValue == 'false' || lowercaseValue == '0' || lowercaseValue == 'no') {
          return false;
        }
      }
      return null;
    }

    // Extract userId - check multiple possible field names
    int? userId;
    if (json['UserId'] != null) {
      userId = json['UserId'] is String ? int.tryParse(json['UserId']) : json['UserId'];
    } else if (json['user_id'] != null) {
      userId = json['user_id'] is String ? int.tryParse(json['user_id']) : json['user_id'];
    } else if (json['userId'] != null) {
      userId = json['userId'] is String ? int.tryParse(json['userId']) : json['userId'];
    }

    // Try to extract seller info from User object if present
    String? sellerName;
    String? sellerFullName;
    String? sellerImage;
    String? sellerProfileImage;
    double? sellerRating;
    double? sellerAverageRating;

    if (json['User'] != null && json['User'] is Map<String, dynamic>) {
      final user = json['User'];

      // Extract seller name
      sellerName = user['name'];
      sellerFullName = user['full_name'] ?? user['fullName'];

      // Extract seller image
      sellerImage = user['image'];
      sellerProfileImage = user['profile_image'] ?? user['profileImage'];

      // Extract seller rating
      final rating = user['rating'] ?? user['average_rating'] ?? user['averageRating'];
      if (rating != null) {
        if (rating is int) {
          sellerRating = rating.toDouble();
          sellerAverageRating = rating.toDouble();
        } else if (rating is double) {
          sellerRating = rating;
          sellerAverageRating = rating;
        } else if (rating is String) {
          try {
            sellerRating = double.parse(rating);
            sellerAverageRating = double.parse(rating);
          } catch (e) {
            print('Error parsing seller rating: $rating');
          }
        }
      }
    } else {
      // Try to extract from top-level fields
      sellerName = json['seller_name'] ?? json['sellerName'];
      sellerFullName = json['seller_full_name'] ?? json['sellerFullName'];
      sellerImage = json['seller_image'] ?? json['sellerImage'];
      sellerProfileImage = json['seller_profile_image'] ?? json['sellerProfileImage'];

      final rating = json['seller_rating'] ?? json['sellerRating'] ??
          json['seller_average_rating'] ?? json['sellerAverageRating'];
      if (rating != null) {
        if (rating is int) {
          sellerRating = rating.toDouble();
          sellerAverageRating = rating.toDouble();
        } else if (rating is double) {
          sellerRating = rating;
          sellerAverageRating = rating;
        } else if (rating is String) {
          try {
            sellerRating = double.parse(rating);
            sellerAverageRating = double.parse(rating);
          } catch (e) {
            print('Error parsing seller rating: $rating');
          }
        }
      }
    }

    // Debug print extracted seller info
    print('Extracted seller info:');
    print('userId: $userId');
    print('sellerName: $sellerName');
    print('sellerFullName: $sellerFullName');
    print('sellerImage: $sellerImage');
    print('sellerProfileImage: $sellerProfileImage');
    print('sellerRating: $sellerRating');
    print('sellerAverageRating: $sellerAverageRating');

    return Product(
      id: json['id'] is String ? int.tryParse(json['id']) ?? 0 : json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Product',
      description: json['description'],
      price: parsePrice(json['price']),
      stockQuantity: parseStockQuantity(json['stock_quantity']),
      categoryName: json['category_name'],
      subCategoryName: json['sub_category_name'],
      images: imagesList,
      isNew: parseIsNew(json['is_new']),

      // Seller information
      userId: userId,
      sellerName: sellerName,
      sellerFullName: sellerFullName,
      sellerImage: sellerImage,
      sellerProfileImage: sellerProfileImage,
      sellerRating: sellerRating,
      sellerAverageRating: sellerAverageRating,
    );
  }
}