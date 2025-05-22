// lib/models/category.dart
import 'package:agritech/models/sub_category.dart';

class Category {
  final int id;
  final String name;
  final String? description;
  final String? image;
  final List<SubCategory>? subCategories;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.subCategories,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    List<SubCategory>? subCats;
    if (json['SubCategories'] != null) {
      subCats = List<SubCategory>.from(
        json['SubCategories'].map((x) => SubCategory.fromJson(x)),
      );
    }

    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      subCategories: subCats,
    );
  }

  get imageUrl => null;
}