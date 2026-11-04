import 'package:google_maps_flutter/google_maps_flutter.dart';

enum GovPlaceCategory {
  attraction,
  hotel,
  restaurant,
  cafe,
}

enum AttractionType {
  beach,
  historic,
  mountain,
  desert,
}

class GovPlace {
  final String id;
  final String govKey;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final String imageAsset;
  final LatLng location;
  final GovPlaceCategory category;
  final AttractionType? attractionType;
  final String? instagramUrl;
  final String? bookingUrl;
  final double? rating;

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
    this.attractionType,
    this.instagramUrl,
    this.bookingUrl,
    this.rating,
  });
}

const List<GovPlace> kGovPlaces = [
  // ================= مسقط =================

  GovPlace(
    id: 'muscat_qurum_beach',
    govKey: 'muscat',
    nameAr: 'شاطئ القرم',
    nameEn: 'Qurum Beach',
    descriptionAr: 'إطلالة بحرية جميلة وممشى رائع.',
    descriptionEn: 'Beautiful beach with a nice walkway.',
    imageAsset: 'assets/places/muscat/qurum_1.jpg',
    location: LatLng(23.6139, 58.4744),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.beach,
  ),

  GovPlace(
    id: 'muscat_muttrah',
    govKey: 'muscat',
    nameAr: 'كورنيش مطرح',
    nameEn: 'Muttrah Corniche',
    descriptionAr: 'ممشى بحري جميل.',
    descriptionEn: 'Nice seaside walkway.',
    imageAsset: 'assets/places/muscat/muttrah_3.jpg',
    location: LatLng(23.6155, 58.5670),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.beach,
  ),

  // ================= مسندم =================

  GovPlace(
    id: 'musandam_khasab_castle',
    govKey: 'musandam',
    nameAr: 'قلعة خصب',
    nameEn: 'Khasab Castle',
    descriptionAr: 'قلعة تاريخية شهيرة في خصب.',
    descriptionEn: 'Historic castle in Khasab.',
    imageAsset: 'assets/places/musandam/khasab_castle.jpg',
    location: LatLng(26.1799, 56.2477),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.historic,
  ),

  GovPlace(
    id: 'musandam_khor_najd',
    govKey: 'musandam',
    nameAr: 'خور نجد',
    nameEn: 'Khor Najd',
    descriptionAr: 'إطلالة خلابة على الجبال والبحر.',
    descriptionEn: 'Amazing fjord view.',
    imageAsset: 'assets/places/musandam/khor_najd.jpg',
    location: LatLng(26.1836, 56.3208),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.mountain,
  ),

  GovPlace(
    id: 'musandam_jebel_harim',
    govKey: 'musandam',
    nameAr: 'جبل حريم',
    nameEn: 'Jebel Harim',
    descriptionAr: 'أعلى قمة في مسندم.',
    descriptionEn: 'Highest peak in Musandam.',
    imageAsset: 'assets/places/musandam/jebel_harim.jpg',
    location: LatLng(26.2460, 56.3010),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.mountain,
  ),

  GovPlace(
    id: 'musandam_bassa_beach',
    govKey: 'musandam',
    nameAr: 'شاطئ البصّة',
    nameEn: 'Bassa Beach',
    descriptionAr: 'شاطئ هادئ وجميل.',
    descriptionEn: 'Quiet and beautiful beach.',
    imageAsset: 'assets/places/musandam/bassa_beach.jpg',
    location: LatLng(26.1915, 56.2572),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.beach,
  ),

  // ===== فندق =====

  GovPlace(
    id: 'musandam_hotel',
    govKey: 'musandam',
    nameAr: 'فندق أتانا خصب',
    nameEn: 'Atana Khasab Hotel',
    descriptionAr: 'فندق بإطلالة جميلة.',
    descriptionEn: 'Hotel with a great view.',
    imageAsset: 'assets/places/musandam/atana_khasab.jpg',
    location: LatLng(26.1923, 56.2468),
    category: GovPlaceCategory.hotel,
    bookingUrl: 'https://www.booking.com/',
    rating: 4.4,
  ),

  // ===== مطعم =====

  GovPlace(
    id: 'musandam_restaurant',
    govKey: 'musandam',
    nameAr: 'مطعم مسندم',
    nameEn: 'Musandam Restaurant',
    descriptionAr: 'مطعم يقدم أكلات متنوعة.',
    descriptionEn: 'Restaurant with various dishes.',
    imageAsset: 'assets/places/musandam/restaurant.jpg',
    location: LatLng(26.1980, 56.2460),
    category: GovPlaceCategory.restaurant,
    rating: 4.3,
  ),

  // ===== كافيه =====

  GovPlace(
    id: 'musandam_cafe',
    govKey: 'musandam',
    nameAr: 'كافيه خصب',
    nameEn: 'Khasab Cafe',
    descriptionAr: 'كوفي هادئ.',
    descriptionEn: 'Cozy cafe.',
    imageAsset: 'assets/places/musandam/cafe.jpg',
    location: LatLng(26.1972, 56.2452),
    category: GovPlaceCategory.cafe,
    rating: 4.5,
  ),
];
