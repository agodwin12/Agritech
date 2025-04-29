// lib/models/product.dart
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final List<String>? images;
  final bool isFeatured;
  final int categoryId;
  final int subCategoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryName;
  final String? subCategoryName;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.images,
    required this.isFeatured,
    required this.categoryId,
    required this.subCategoryId,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.subCategoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String>? productImages;
    if (json['images'] != null) {
      productImages = List<String>.from(json['images']);
    }

    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      stockQuantity: json['stock_quantity'],
      images: productImages,
      isFeatured: json['is_featured'] ?? false,
      categoryId: json['CategoryId'],
      subCategoryId: json['SubCategoryId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      categoryName: json['Category'] != null ? json['Category']['name'] : null,
      subCategoryName: json['SubCategory'] != null ? json['SubCategory']['name'] : null,
    );
  }
}