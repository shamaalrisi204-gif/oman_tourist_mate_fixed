// lib/services/places_repo.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_data.dart';

class PlacesRepo {
  // قائمة أماكن بسيطة كبداية (تقدرين تزيديها لاحقاً)
  static final List<PlaceData> all = <PlaceData>[
    PlaceData(
      id: 'sohar-beach',
      nameAr: 'شاطئ صحار',
      nameEn: 'Sohar Beach',
      category: PlaceCategory.sea,
      governorate: 'شمال الباطنة',
      city: 'صحار',
      latlng: const LatLng(24.3509, 56.7070),
    ),
    PlaceData(
      id: 'qurum-beach',
      nameAr: 'شاطئ القرم',
      nameEn: 'Qurum Beach',
      category: PlaceCategory.sea,
      governorate: 'مسقط',
      city: 'مسقط',
      latlng: const LatLng(23.6139, 58.4645),
    ),
    PlaceData(
      id: 'sur-sea',
      nameAr: 'شاطئ صور',
      nameEn: 'Sur Beach',
      category: PlaceCategory.sea,
      governorate: 'جنوب الشرقية',
      city: 'صور',
      latlng: const LatLng(22.5733, 59.5289),
    ),
    PlaceData(
      id: 'mugsail',
      nameAr: 'شاطئ المغسيل',
      nameEn: 'Al Mughsail Beach',
      category: PlaceCategory.sea,
      governorate: 'ظفار',
      city: 'صلالة',
      latlng: const LatLng(16.8895, 53.7362),
    ),
    // أمثلة تاريخية
    PlaceData(
      id: 'nizwa-fort',
      nameAr: 'قلعة نزوى',
      nameEn: 'Nizwa Fort',
      category: PlaceCategory.historical,
      governorate: 'الداخلية',
      city: 'نزوى',
      latlng: const LatLng(22.9333, 57.5333),
    ),
  ];
  static List<PlaceData> byCategory(PlaceCategory c) =>
      all.where((p) => p.category == c).toList();

  /// مدن مقترحة للإقامة + مراكزها على الخريطة
  static List<String> get stayCities =>
      ['مسقط', 'صحار', 'صور', 'صلالة', 'نزوى'];
  static Map<String, LatLng> get stayCityCenters => {
        'مسقط': const LatLng(23.5880, 58.3829),
        'صحار': const LatLng(24.3509, 56.7070),
        'صور': const LatLng(22.5667, 59.5289),
        'صلالة': const LatLng(17.0151, 54.0924),
        'نزوى': const LatLng(22.9333, 57.5333),
      };

  /// خيارات الفئات لواجهة الأسئلة
  static List<Map<String, String>> get categories => [
        {'key': 'sea', 'ar': 'البحر', 'en': 'Sea'},
        {'key': 'desert', 'ar': 'البر', 'en': 'Desert'},
        {'key': 'historical', 'ar': 'تاريخي', 'en': 'Historical'},
      ];
}
