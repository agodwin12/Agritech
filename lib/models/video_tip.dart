class VideoTip {
  final int id;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final String category;

  VideoTip({
    required this.id,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.category,
  });

  factory VideoTip.fromJson(Map<String, dynamic> json) {
    return VideoTip(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      videoUrl: json['video_url'],
      thumbnailUrl: json['thumbnail_url'] ?? '',
      category: json['VideoCategory']?['name'] ?? 'Unknown',
    );
  }
}
