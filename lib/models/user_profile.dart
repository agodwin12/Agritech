// lib/models/user_profile.dart
import 'package:flutter/foundation.dart';
import 'product.dart';

class UserProfile {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final DateTime? dateOfBirth;
  final String? profileImage;
  final String? bio;
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? tiktok;
  final DateTime createdAt;
  final double averageRating;
  final List<Product>? products;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.dateOfBirth,
    this.profileImage,
    this.bio,
    this.facebook,
    this.instagram,
    this.twitter,
    this.tiktok,
    required this.createdAt,
    required this.averageRating,
    this.products,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    List<Product>? productsList;
    if (json['products'] != null) {
      productsList = (json['products'] as List)
          .map((productJson) => Product.fromJson(productJson))
          .toList();
    }

    return UserProfile(
      id: json['id'],
      fullName: json['full_name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'])
          : null,
      profileImage: json['profile_image'],
      bio: json['bio'],
      facebook: json['facebook'],
      instagram: json['instagram'],
      twitter: json['twitter'],
      tiktok: json['tiktok'],
      createdAt: DateTime.parse(json['created_at']),
      averageRating: double.parse(json['average_rating'] ?? '0.0'),
      products: productsList,
    );
  }

  @override
  String toString() {
    return 'UserProfile{id: $id, fullName: $fullName, email: $email, products: ${products?.length ?? 0} items}';
  }
}