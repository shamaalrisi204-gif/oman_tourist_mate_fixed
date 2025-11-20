// lib/core/places_service.dart

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'secrets.dart';

class PlaceResult {
  final String name;

  final String address;

  final double? rating;

  final String? photoUrl;

  PlaceResult({
    required this.name,
    required this.address,
    this.rating,
    this.photoUrl,
  });
}

class PlacesService {
  final String _apiKey = Secrets.googleMapsKey;

  /// البحث عن الأماكن: فنادق - مطاعم - أماكن سياحية

  Future<List<PlaceResult>> searchPlaces({
    required String city,
    required String type, // lodging, restaurant, tourist_attraction
  }) async {
    final query = "$type in $city, Oman";

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/textsearch/json'
      '?query=${Uri.encodeComponent(query)}'
      '&key=$_apiKey',
    );

    final res = await http.get(url);

    if (res.statusCode != 200) {
      print("❌ Google API ERROR: ${res.statusCode}");

      return [];
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;

    final results = (data["results"] as List? ?? []);

    return results.take(6).map((raw) {
      final m = raw as Map<String, dynamic>;

      final name = m["name"] ?? "Unknown name";

      final address = m["formatted_address"] ?? "";

      final rating = (m["rating"] as num?)?.toDouble();

      // ---- استرجاع صورة المكان ----

      String? photoUrl;

      final photos = m["photos"] as List?;

      if (photos != null && photos.isNotEmpty) {
        final ref = photos.first["photo_reference"];

        if (ref != null) {
          photoUrl = "https://maps.googleapis.com/maps/api/place/photo"
              "?maxwidth=1000"
              "&photo_reference=$ref"
              "&key=$_apiKey";
        }
      }

      return PlaceResult(
        name: name,
        address: address,
        rating: rating,
        photoUrl: photoUrl,
      );
    }).toList();
  }
}
