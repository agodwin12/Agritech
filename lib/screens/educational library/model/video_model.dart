// lib/models/video_model.dart
class Video {
  final int id;
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final int categoryId;
  final String? categoryName;
  final Duration? duration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Video({
    required this.id,
    required this.title,
    required this.description,
    this.thumbnailUrl,
    this.videoUrl,
    required this.categoryId,
    this.categoryName,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      videoUrl: json['video_url'],
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'],
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (videoUrl != null) 'video_url': videoUrl,
      'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (duration != null) 'duration': duration!.inSeconds,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  String get fullThumbnailUrl => thumbnailUrl ?? '';
  String get fullVideoUrl => videoUrl ?? '';
  String get formattedDuration {
    if (duration == null) return '';
    final hours = duration!.inHours;
    final minutes = duration!.inMinutes.remainder(60);
    final seconds = duration!.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'Video(id: $id, title: $title, categoryId: $categoryId, duration: $formattedDuration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Video && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}