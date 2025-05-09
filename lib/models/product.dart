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
    if (json['images'] != null && json['images'] is List) {
      productImages = List<String>.from(json['images']);
    }

    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unnamed Product',
      description: json['description'],
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      stockQuantity: json['stock_quantity'] ?? 0,
      images: productImages,
      isFeatured: json['is_featured'] ?? false,
      categoryId: json['CategoryId'] ?? 0,
      subCategoryId: json['SubCategoryId'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      categoryName: json['Category']?['name'],
      subCategoryName: json['SubCategory']?['name'],
    );
  }
}