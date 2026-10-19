import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/media_item.dart';

/// Jikan: free MyAnimeList API, no key needed.
class MediaApi {
  static const _base = 'https://api.jikan.moe/v4';

  static Future<List<MediaItem>> topAnime() =>
      _fetch('$_base/top/anime?limit=10', 'Anime');

  static Future<List<MediaItem>> search(String query, String type) {
    final q = Uri.encodeQueryComponent(query);
    final path = type == 'Manga' ? 'manga' : 'anime';
    final extra = type == 'Movie' ? '&type=movie' : '';
    return _fetch('$_base/$path?q=$q&limit=15$extra', type);
  }

  static Future<List<MediaItem>> _fetch(String url, String type) async {
    final res =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Server returned ${res.statusCode}');
    }
    final data = jsonDecode(res.body)['data'] as List;
    return data.map<MediaItem>((e) {
      final title = (e['title_english'] ?? e['title'] ?? 'Untitled') as String;
      final image = e['images']?['jpg']?['image_url'] as String?;
      return MediaItem(
        malId: e['mal_id'] as int,
        title: title,
        imageUrl: image,
        type: type,
      );
    }).toList();
  }
}