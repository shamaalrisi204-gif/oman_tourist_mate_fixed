// lib/models/place_data.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum PlaceCategory { sea, desert, mountain, historical, park, souq }

class PlaceData {
  final String id;
  final String nameAr;
  final String nameEn;
  final PlaceCategory category;
  final String governorate; // المحافظة
  final String city; // المدينة/الولاية
  final LatLng latlng;
  const PlaceData({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.category,
    required this.governorate,
    required this.city,
    required this.latlng,
  });
  Map<String, dynamic> toJson() => {
        'id': id,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'category': category.name,
        'governorate': governorate,
        'city': city,
        'lat': latlng.latitude,
        'lng': latlng.longitude,
      };
  factory PlaceData.fromJson(Map<String, dynamic> m) => PlaceData(
        id: m['id'] as String,
        nameAr: m['nameAr'] as String,
        nameEn: m['nameEn'] as String,
        category: PlaceCategory.values.firstWhere(
          (e) => e.name == m['category'],
          orElse: () => PlaceCategory.sea,
        ),
        governorate: m['governorate'] as String,
        city: m['city'] as String,
        latlng:
            LatLng((m['lat'] as num).toDouble(), (m['lng'] as num).toDouble()),
      );
  static String displayName(PlaceData p, bool isArabic) =>
      isArabic ? p.nameAr : p.nameEn;
}
