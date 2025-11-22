// lib/models/gov_places.dart
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// نوع المكان داخل شاشة المحافظة
enum GovPlaceCategory {
  attraction, // مكان سياحي / مَعْلَم
  hotel, // فندق
  restaurant, // مطعم
  cafe, // كوفي
}

class GovPlace {
  final String id;
  final String
      govKey; // نفس مفاتيح المحافظات: muscat, sohar, nizwa, salalah ...
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String imageAsset; // صورة من assets
  final LatLng location;
  final GovPlaceCategory category;

  const GovPlace({
    required this.id,
    required this.govKey,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.imageAsset,
    required this.location,
    required this.category,
  });
}

/// أمثلة مبدئية لأربع محافظات
const List<GovPlace> kGovPlaces = [
  // ---------- مسقط ----------
  GovPlace(
    id: 'muttrah_corniche',
    govKey: 'muscat',
    nameAr: 'كورنيش مطرح',
    nameEn: 'Muttrah Corniche',
    descriptionAr: 'ممشى بحري جميل قريب من الأسواق والمطاعم.',
    descriptionEn: 'Beautiful seaside corniche near souqs and cafes.',
    imageAsset: 'assets/places/muscat/muttrah_1.jpg',
    location: LatLng(23.6155, 58.5670),
    category: GovPlaceCategory.attraction,
  ),
  GovPlace(
    id: 'muscat_hotel_sample',
    govKey: 'muscat',
    nameAr: 'فندق تجريبي في مسقط',
    nameEn: 'Sample Hotel Muscat',
    descriptionAr: 'نموذج لفندق، عدّلي الاسم والبيانات لاحقاً.',
    descriptionEn: 'Hotel sample – update later with real data.',
    imageAsset: 'assets/places/muscat/hotel_sample.jpg',
    location: LatLng(23.59, 58.45),
    category: GovPlaceCategory.hotel,
  ),
  GovPlace(
    id: 'muscat_restaurant_sample',
    govKey: 'muscat',
    nameAr: 'مطعم تجريبي في مسقط',
    nameEn: 'Sample Restaurant Muscat',
    descriptionAr: 'مثال لمطعم، استبدليه بمطعم حقيقي من مسقط.',
    descriptionEn: 'Example restaurant, replace with a real one.',
    imageAsset: 'assets/places/muscat/restaurant_sample.jpg',
    location: LatLng(23.60, 58.47),
    category: GovPlaceCategory.restaurant,
  ),
  GovPlace(
    id: 'muscat_cafe_sample',
    govKey: 'muscat',
    nameAr: 'كوفي تجريبي في مسقط',
    nameEn: 'Sample Cafe Muscat',
    descriptionAr: 'كوفي على البحر مثلاً – صورة مبدئية.',
    descriptionEn: 'Seaside style cafe – sample data.',
    imageAsset: 'assets/places/muscat/cafe_sample.jpg',
    location: LatLng(23.605, 58.48),
    category: GovPlaceCategory.cafe,
  ),

  // ---------- صحار ----------
  GovPlace(
    id: 'sohar_beach',
    govKey: 'albatinahnorth', // نفس govKey اللي تستخدمينه لصحار في الخريطة
    nameAr: 'شاطئ صحار',
    nameEn: 'Sohar Beach',
    descriptionAr: 'شاطئ هادئ مناسب للمشي والجلسات.',
    descriptionEn: 'Calm beach suitable for walking and relaxing.',
    imageAsset: 'assets/places/sohar/beach_1.jpg',
    location: LatLng(24.3539, 56.7075),
    category: GovPlaceCategory.attraction,
  ),
  // أضيفي بعدها فنادق/مطاعم/كوفيات صحار بنفس الشكل...

  // ---------- نزوى ----------
  GovPlace(
    id: 'nizwa_fort',
    govKey: 'addakhliyah',
    nameAr: 'قلعة نزوى',
    nameEn: 'Nizwa Fort',
    descriptionAr: 'من أشهر المعالم التاريخية في عُمان.',
    descriptionEn: 'One of the most famous historic forts in Oman.',
    imageAsset: 'assets/places/nizwa/fort_1.jpg',
    location: LatLng(22.9333, 57.5333),
    category: GovPlaceCategory.attraction,
  ),

  // ---------- صلالة ----------
  GovPlace(
    id: 'salalah_beach',
    govKey: 'dhofar',
    nameAr: 'شاطئ صلالة',
    nameEn: 'Salalah Beach',
    descriptionAr: 'شاطئ جميل خاصة وقت الخريف.',
    descriptionEn: 'Beautiful beach, especially during Khareef.',
    imageAsset: 'assets/places/salalah/beach_1.jpg',
    location: LatLng(17.0150, 54.0924),
    category: GovPlaceCategory.attraction,
  ),
];
