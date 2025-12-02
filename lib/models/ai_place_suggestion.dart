// lib/models/ai_place_suggestion.dart

class AiPlaceSuggestion {
  final String id;

  final String nameEn;

  final String nameAr;

  final String governorate;

  final String city;

  final String type;

  final String descriptionEn;

  final String descriptionAr;

  final String imageUrl;

  final double? rating;

  final double? lat;

  final double? lng;

  final String source; // "accommodations" أو "attractions"

  const AiPlaceSuggestion({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.governorate,
    required this.city,
    required this.type,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.imageUrl,
    required this.source,
    this.rating,
    this.lat,
    this.lng,
  });

  String get displayName => nameAr.isNotEmpty ? nameAr : nameEn;

  String get displayDescription =>
      descriptionAr.isNotEmpty ? descriptionAr : descriptionEn;

  bool get hasLocation => lat != null && lng != null;

  /// نستخدمها لما نرجّع Map فيه "id" من TourismRepository

  factory AiPlaceSuggestion.fromMap(
    Map<String, dynamic> data, {
    required String source,
  }) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;

      if (v is num) return v.toDouble();

      return double.tryParse(v.toString());
    }

    // 👇 دالة صغيرة تقصّ المسافات الزايدة من النصوص

    String _s(String key) =>
        (data[key]?.toString().trim() ?? ''); // trim مهم هنا

    return AiPlaceSuggestion(
      id: _s('id'),

      nameEn: _s('nameEn'),

      nameAr: _s('nameAr'),

      governorate: _s('governorate'),

      city: _s('city'),

      type: _s('type'),

      descriptionEn: _s('descriptionEnShort'),

      descriptionAr: _s('descriptionArShort'),

      imageUrl: _s('imageUrl'), // 👈 هنا نضمن ما فيه مسافة

      rating: _toDouble(data['rating']),

      lat: _toDouble(data['lat']),

      lng: _toDouble(data['lng']),

      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameEn': nameEn,
        'nameAr': nameAr,
        'governorate': governorate,
        'city': city,
        'type': type,
        'descriptionEnShort': descriptionEn,
        'descriptionArShort': descriptionAr,
        'imageUrl': imageUrl,
        'rating': rating,
        'lat': lat,
        'lng': lng,
        'source': source,
      };
}
