class VideoCategory {
  final int id;
  final String name;
  final String? description;

  VideoCategory({
    required this.id,
    required this.name,
    this.description,
  });

  factory VideoCategory.fromJson(Map<String, dynamic> json) {
    return VideoCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}
