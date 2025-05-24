// lib/models/category_model.dart
class Category {
  final int id;
  final String name;
  final String type; // 'ebook', 'video', or 'both'
  final int? videoId; // Used when type is 'both'

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.videoId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? 'ebook',
      videoId: json['video_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      if (videoId != null) 'video_id': videoId,
    };
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type, videoId: $videoId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.videoId == videoId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ type.hashCode ^ videoId.hashCode;
  }
}