// lib/models/review.dart
class Review {
  final int id;
  final int productId;
  final int? userId;
  final String? userName;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.productId,
    this.userId,
    this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Helper function to parse int values safely
    int parseIntSafely(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('Error parsing int: $value');
          return 0;
        }
      }
      return 0;
    }

    // Helper function to parse nullable int values
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('Error parsing nullable int: $value');
          return null;
        }
      }
      return null;
    }

    // Helper function to parse double values safely
    double parseDoubleSafely(dynamic value) {
      if (value == null) return 0.0;
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          print('Error parsing double: $value');
          return 0.0;
        }
      }
      return 0.0;
    }

    return Review(
      id: parseIntSafely(json['id']),
      productId: parseIntSafely(json['product_id']),
      userId: parseNullableInt(json['user_id']),
      userName: json['user_name'],
      rating: parseDoubleSafely(json['rating']),
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}