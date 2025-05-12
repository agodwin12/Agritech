// lib/models/review.dart
class Review {
  final int? id;
  final int productId;
  final int? userId;
  final String? userName;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  Review({
    this.id,
    required this.productId,
    this.userId,
    this.userName,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      productId: json['product_id'] ?? json['productId'],
      userId: json['user_id'],
      userName: json['User']?['full_name'],
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}