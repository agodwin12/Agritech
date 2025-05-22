class Ebook {
  final int id;
  final String title;
  final String description;
  final double price;
  final String fileUrl;
  final String coverImage;
  final bool isApproved;
  final String category;
  final String authorName;

  Ebook({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.fileUrl,
    required this.coverImage,
    required this.isApproved,
    required this.category,
    required this.authorName,
  });

  factory Ebook.fromJson(Map<String, dynamic> json) {
    return Ebook(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      fileUrl: json['file_url'],
      coverImage: json['cover_image'] ?? '',
      isApproved: json['is_approved'] ?? false,
      category: json['EbookCategory']?['name'] ?? 'Unknown',
      authorName: json['User']?['full_name'] ?? 'Anonymous',
    );
  }
}
