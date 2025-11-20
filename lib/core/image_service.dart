// lib/core/image_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secrets.dart';

class ImageService {
  static const String _baseUrl = 'https://api.unsplash.com';

  /// أخذ ٣ صور تقريباً بناءً على الكلمة المفتاحية
  static Future<List<String>> searchImages(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/search/photos'
      '?query=$query'
      '&per_page=3'
      '&orientation=landscape',
    );

    final res = await http.get(
      uri,
      headers: {
        'Accept-Version': 'v1',
        'Authorization': 'Client-ID ${Secrets.unsplashAccessKey}',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Unsplash error: ${res.statusCode} ${res.reasonPhrase}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;

    final urls = <String>[];
    for (final item in results) {
      final urlsObj = item['urls'] as Map<String, dynamic>?;
      final regular = urlsObj?['regular'] as String?;
      if (regular != null) {
        urls.add(regular);
      }
    }

    return urls;
  }

  /// نطلّع كلمة بحث مناسبة لصور من نص المستخدم
  static String queryFromUserText(String userText) {
    final lower = userText.toLowerCase();

    final cities = [
      'muscat',
      'sohar',
      'salalah',
      'nizwa',
      'sur',
      'rustaq',
      'ibra',
      'barka',
      'shinas',
      'al buraimi',
      'khasab',
      'masirah',
    ];

    for (final c in cities) {
      if (lower.contains(c)) {
        return '$c oman';
      }
    }

    // لو ما لقى مدينة، نضيف oman عشان الصور تكون سياحية
    return '$userText oman';
  }
}
