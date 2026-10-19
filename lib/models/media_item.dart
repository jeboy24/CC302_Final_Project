import '../constants.dart';

class MediaItem {
  final int malId;
  final String title;
  final String? imageUrl;
  final String type; // Anime, Movie, Manga
  String status;
  DateTime updatedAt;

  MediaItem({
    required this.malId,
    required this.title,
    this.imageUrl,
    required this.type,
    String? status,
    DateTime? updatedAt,
  })  : status = status ?? defaultStatus(type),
        updatedAt = updatedAt ?? DateTime.now();

  String get key => '$type-$malId';

  Map<String, dynamic> toJson() => {
        'malId': malId,
        'title': title,
        'imageUrl': imageUrl,
        'type': type,
        'status': status,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory MediaItem.fromJson(Map<String, dynamic> j) => MediaItem(
        malId: j['malId'] as int,
        title: j['title'] as String,
        imageUrl: j['imageUrl'] as String?,
        type: j['type'] as String,
        status: j['status'] as String?,
        updatedAt: DateTime.tryParse(j['updatedAt'] ?? ''),
      );
}