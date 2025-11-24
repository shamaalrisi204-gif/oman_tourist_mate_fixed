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

    return AiPlaceSuggestion(
      id: data['id']?.toString() ?? '',
      nameEn: data['nameEn']?.toString() ?? '',
      nameAr: data['nameAr']?.toString() ?? '',
      governorate: data['governorate']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      type: data['type']?.toString() ?? '',
      descriptionEn: data['descriptionEnShort']?.toString() ?? '',
      descriptionAr: data['descriptionArShort']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString() ?? '',
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
