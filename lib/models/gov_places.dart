// lib/models/gov_places.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// نوع المكان داخل شاشة المحافظة

enum GovPlaceCategory {
  attraction, // مكان سياحي / مَعْلَم

  hotel, // فندق

  restaurant, // مطعم

  cafe, // كوفي
}

/// نوع المكان السياحي نفسه (بحري / تاريخي / جبلي / بر)

enum AttractionType {
  beach,

  historic,

  mountain,

  desert,
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

  /// لو كان المكان "سياحي" نقدر نحدد نوعه

  final AttractionType? attractionType;

  /// جديد:

  final String? instagramUrl; // حساب إنستغرام (للمطعم / الكوفي)

  final String? bookingUrl; // رابط حجز (Booking / موقع الفندق)

  final double? rating; // تقييم من 5 مثلاً

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

/// أمثلة مبدئية لمسقط + بعض الأماكن من المحافظات الأخرى

const List<GovPlace> kGovPlaces = [
  // ---------- مسقط: أماكن بحريّة ----------

  GovPlace(
    id: 'muscat_qurum_beach_1',
    govKey: 'muscat',
    nameAr: 'شاطئ القرم (منطقة ١)',
    nameEn: 'Qurum Beach Area 1',
    descriptionAr: 'إطلالة بحرية جميلة وممشى على البحر.',
    descriptionEn: 'Nice seaside walk and beach area.',
    imageAsset: 'assets/places/muscat/qurum_1.jpg',
    location: LatLng(23.6139, 58.4744),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.beach,
  ),

  GovPlace(
    id: 'muscat_qurum_beach_2',
    govKey: 'muscat',
    nameAr: 'شاطئ القرم (منطقة ٢)',
    nameEn: 'Qurum Beach Area 2',
    descriptionAr: 'مكان مناسب للجلسات العائلية على البحر.',
    descriptionEn: 'Good spot for family seaside sitting.',
    imageAsset: 'assets/places/muscat/qurum_2.jpg',
    location: LatLng(23.6145, 58.4760),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.beach,
  ),

  GovPlace(
    id: 'muscat_muttrah_sea',
    govKey: 'muscat',
    nameAr: 'كورنيش مطرح – الواجهة البحرية',
    nameEn: 'Muttrah Corniche (Seafront)',
    descriptionAr: 'ممشى بحري مع إطلالة على الميناء والأسواق.',
    descriptionEn: 'Seafront corniche with view of the port and souqs.',
    imageAsset: 'assets/places/muscat/muttrah_3.jpg',
    location: LatLng(23.6155, 58.5670),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.beach,
  ),

  // ---------- مسقط: أماكن تاريخية ----------

  GovPlace(
    id: 'muscat_muttrah_old_souk',
    govKey: 'muscat',
    nameAr: 'سوق مطرح القديم',
    nameEn: 'Muttrah Old Souq',
    descriptionAr: 'سوق شعبي تاريخي بالقرب من الكورنيش.',
    descriptionEn: 'Historic souq near the corniche.',
    imageAsset: 'assets/places/muscat/muttrah_1.jpg',
    location: LatLng(23.6165, 58.5660),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.historic,
  ),

  GovPlace(
    id: 'muscat_muttrah_gate',
    govKey: 'muscat',
    nameAr: 'بوابة مطرح',
    nameEn: 'Muttrah Gate',
    descriptionAr: 'معلم تاريخي يطل على المدينة.',
    descriptionEn: 'Historic gate with a view over the city.',
    imageAsset: 'assets/places/muscat/muttrah_2.jpg',
    location: LatLng(23.6160, 58.5650),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.historic,
  ),

  GovPlace(
    id: 'muscat_qasr_alalam',
    govKey: 'muscat',
    nameAr: 'قصر العلم',
    nameEn: 'Qasr Al Alam',
    descriptionAr: 'قصر تاريخي جميل في مسقط القديمة.',
    descriptionEn: 'Beautiful historic palace in Old Muscat.',
    imageAsset: 'assets/places/muscat/qasr_alalm.jpg',
    location: LatLng(23.6169, 58.5940),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.historic,
  ),

  // ---------- مسقط: فندق ----------

  GovPlace(
    id: 'muscat_hilton_garden_inn',

    govKey: 'muscat',

    nameAr: 'هيلتون جاردن إن مسقط الخوير',

    nameEn: 'Hilton Garden Inn Muscat Al Khuwair',

    descriptionAr:
        'فندق عصري بخدمة واي فاي مجاني، حمام سباحة خارجي ومواقف سيارات مجانية.',

    descriptionEn:
        'Modern hotel with free Wi-Fi, outdoor pool and free parking.',

    imageAsset: 'assets/places/muscat/hotel.jpg',

    location: LatLng(23.5880, 58.4340), // تقديري

    category: GovPlaceCategory.hotel,

    bookingUrl:
        'https://www.hilton.com/', // بدّليه برابط Booking أو صفحة الفندق

    rating: 4.4,
  ),

  // ---------- مسقط: مطعم (حاجي حسن) ----------

  GovPlace(
    id: 'muscat_haci_hasan',

    govKey: 'muscat',

    nameAr: 'حاجي حسن أوغولاري',

    nameEn: 'Haci Hasan Ogullari',

    descriptionAr: 'مطعم تركي وبقلاوة تركية في مسقط.',

    descriptionEn: 'Turkish restaurant and baklava store in Muscat.',

    imageAsset: 'assets/places/muscat/resturant_muscat.jpg',

    location: LatLng(23.624666, 58.1520101), // عدّلي الإحداثيات لو حابة

    category: GovPlaceCategory.restaurant,

    instagramUrl: 'https://www.instagram.com/hacihasan.om/',

    rating: 4.7,
  ),

  // ---------- صحار ----------

  GovPlace(
    id: 'sohar_beach',
    govKey: 'albatinahnorth',
    nameAr: 'شاطئ صحار',
    nameEn: 'Sohar Beach',
    descriptionAr: 'شاطئ هادئ مناسب للمشي والجلسات.',
    descriptionEn: 'Calm beach suitable for walking and relaxing.',
    imageAsset: 'assets/places/sohar/beach_1.jpg',
    location: LatLng(24.3539, 56.7075),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.beach,
  ),

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
    attractionType: AttractionType.historic,
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
    attractionType: AttractionType.beach,
  ),
];
