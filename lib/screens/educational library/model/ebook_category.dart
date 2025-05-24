class EbookCategory {
  final int id;
  final String name;
  final String? description;

  EbookCategory({
    required this.id,
    required this.name,
    this.description,
  });

  factory EbookCategory.fromJson(Map<String, dynamic> json) {
    return EbookCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}
