// lib/models/sub_category.dart
class SubCategory {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final int categoryId;

  SubCategory({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.categoryId,
  });

  factory SubCategory.fromJson(Map<String, dynamic> json) {
    return SubCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      categoryId: json['category_id'],
    );
  }
}