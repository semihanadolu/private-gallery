enum MediaType { image, video }

class MediaItem {
  final String id;
  final String path;
  final MediaType type;
  final DateTime createdAt;
  final String? thumbnailPath;

  MediaItem({
    required this.id,
    required this.path,
    required this.type,
    required this.createdAt,
    this.thumbnailPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'type': type.toString(),
      'createdAt': createdAt.toIso8601String(),
      'thumbnailPath': thumbnailPath,
    };
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      path: json['path'],
      type: MediaType.values.firstWhere((e) => e.toString() == json['type']),
      createdAt: DateTime.parse(json['createdAt']),
      thumbnailPath: json['thumbnailPath'],
    );
  }
}
