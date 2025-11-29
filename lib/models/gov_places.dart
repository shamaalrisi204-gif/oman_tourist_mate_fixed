// lib/models/gov_places.dart

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

  final String
      govKey; // نفس مفاتيح المحافظات: muscat, sohar, nizwa, salalah ...

  final String nameAr;

  final String nameEn;

  final String descriptionAr;

  final String descriptionEn;

  final String imageAsset; // صورة من assets

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

  GovPlace(
    id: 'muscat_qaha_cafe',
    govKey: 'muscat',
    nameAr: 'قَهَا كافيه',
    nameEn: 'Qaha Cafe',
    descriptionAr: 'كوفي متخصص بالقهوة والحلويات.',
    descriptionEn: 'Specialty coffee and desserts.',
    imageAsset: 'assets/places/muscat/qaha.jpg',
    location: LatLng(23.5681589, 58.4149115),
    category: GovPlaceCategory.cafe,
    instagramUrl: 'https://www.instagram.com/qahacafe/',
    rating: 4.6,
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

  // ---------- صحار: فندق ميركيور ----------

  GovPlace(
    id: 'sohar_mercure_hotel',

    govKey: 'albatinahnorth', // نفس مفتاح صحار

    nameAr: 'فندق ميركيور صحار',

    nameEn: 'Mercure Sohar',

    descriptionAr:
        'فندق مريح في صحار مع مسبح خارجي وخدمة واي فاي مجاني وموقع قريب من الخدمات.',

    descriptionEn:
        'Comfortable hotel in Sohar with outdoor pool, free Wi-Fi and a convenient location.',

    imageAsset: 'assets/places/sohar/mercure_sohar.jpg',

    // الإحداثيات من الخريطة

    location: LatLng(24.3290712, 56.7407024),

    category: GovPlaceCategory.hotel,

    bookingUrl: 'https://www.booking.com/hotel/om/mercure-sohar.ar.html',

    rating: 4.5, // عدّلي الرقم لو حابة
  ),

  // ---------- صحار: مطعم الخاطر ----------

  GovPlace(
    id: 'sohar_alkhater_restaurant',

    govKey: 'albatinahnorth',

    nameAr: 'مطعم الخاطر',

    nameEn: 'Al Khater Restaurant',

    descriptionAr:
        'مطعم يقدم مشاوي وباستا وبيتزا في حدائق النخيل بجانب رد تاغ في صحار.',

    descriptionEn:
        'Restaurant serving grills, pasta and pizza in Palm Gardens next to Red Tag in Sohar.',

    imageAsset: 'assets/places/sohar/alkhater.jpg',

    // الإحداثيات من الخريطة

    location: LatLng(24.3366920, 56.7354403),

    category: GovPlaceCategory.restaurant,

    instagramUrl: 'https://www.instagram.com/alkhater.om/',

    rating: 4.6, // تقديري – تقدرين تغيّرينه
  ),
  GovPlace(
    id: 'sohar_robusta_cafe',
    govKey: 'albatinahnorth',
    nameAr: 'روبوستا كافيه',
    nameEn: 'Robusta Cafe',
    descriptionAr: 'كوفي مختص يقدم قهوة عالية الجودة وإطلالة جميلة.',
    descriptionEn: 'Specialty coffee shop with a nice view and great drinks.',
    imageAsset: 'assets/places/sohar/robusta.jpg',
    location: LatLng(24.3663161, 56.7478676),
    category: GovPlaceCategory.cafe,
    instagramUrl: 'https://www.instagram.com/robusta__cafe/',
    rating: 4.6,
  ),

// ---------- صلالة / ظفار ----------

  GovPlace(
    id: 'salalah_corniche',

    govKey: 'dhofar',

    nameAr: 'كورنيش صلالة',

    nameEn: 'Salalah Corniche',

    descriptionAr:
        'ممشى بحري جميل مع جلسات مطلة على البحر وأشجار النخيل، مناسب للعائلات خصوصاً في موسم الخريف.',

    descriptionEn:
        'Seaside corniche with palm trees and sea views, popular for families especially during Khareef season.',

    imageAsset: 'assets/places/salalah/corniche.jpg',

    location: LatLng(17.0110, 54.0920), // عدّليها من Google Maps لو حابة

    category: GovPlaceCategory.attraction,

    attractionType: AttractionType.beach,
  ),

  GovPlace(
    id: 'salalah_al_haffa_beach',
    govKey: 'dhofar',
    nameAr: 'شاطئ الحافة',
    nameEn: 'Al Haffa Beach',
    descriptionAr:
        'أحد أشهر شواطئ صلالة، رمل أبيض ناعم وقريب من سوق الحافة التقليدي.',
    descriptionEn:
        'One of Salalah’s most famous beaches with soft white sand, close to Al Haffa traditional market.',
    imageAsset: 'assets/places/salalah/haffa_beach.jpg',
    location: LatLng(17.0100, 54.1040),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.beach,
  ),

  GovPlace(
    id: 'salalah_al_baleed_park',
    govKey: 'dhofar',
    nameAr: 'منتزه البليد الأثري',
    nameEn: 'Al Baleed Archaeological Park',
    descriptionAr:
        'موقع أثري مهم يروي تاريخ اللبان والحضارة البحرية في ظفار، مع متحف جميل وإطلالة على البحر.',
    descriptionEn:
        'Important archaeological site telling the story of frankincense and maritime history, with a nice museum and sea views.',
    imageAsset: 'assets/places/salalah/al_baleed.jpg',
    location: LatLng(17.0175, 54.1090),
    category: GovPlaceCategory.attraction,
    attractionType: AttractionType.historic,
  ),

// ---------- صلالة: فندق ميليـنيوم ----------

  GovPlace(
    id: 'salalah_millennium_resort',

    govKey: 'dhofar',

    nameAr: 'منتجع ميلينيوم صلالة',

    nameEn: 'Millennium Resort Salalah',

    descriptionAr:
        'منتجع راقي مع مسابح ومرافق عائلية، يقع في صلالة بالقرب من الشاطئ.',

    descriptionEn:
        'Upscale resort with pools and family facilities, located in Salalah near the beach.',

    imageAsset:
        'assets/places/salalah/millennium_resort.jpg', // عدّلي اسم الصورة حسب ملفك

    location: LatLng(
      17.0366370, // latitude

      54.1703445, // longitude
    ),

    category: GovPlaceCategory.hotel,

    bookingUrl:
        'https://www.booking.com/hotel/om/millennium-resort-salalah-salalah.ar.html',

    rating: 4.5, // من Booking (قدّري أو عدّليه)
  ),

  // ---------- صلالة: مطعم/كافيه لت لن على شاطئ الدهاريز ----------

  GovPlace(
    id: 'salalah_lit_lin',

    govKey: 'dhofar',

    nameAr: 'لت لن | LIT LIN',

    nameEn: 'LIT LIN Restaurant & Café',

    descriptionAr:
        'مطعم وكافيه على شاطئ الدهاريز في صلالة بإطلالة بحرية جميلة.',

    descriptionEn:
        'Restaurant & café at Dhareez beach in Salalah with a nice sea view.',

    imageAsset:
        'assets/places/salalah/lit_lin.jpg', // حطي صورة من عندك في assets

    location: LatLng(
      17.010949, // latitude من الخريطة

      54.17153, // longitude من الخريطة
    ),

    category: GovPlaceCategory.restaurant,

    instagramUrl: 'https://www.instagram.com/litlin.om/',

    rating: 4.5, // تقديري، عدّليه لو حابة
  ),

  GovPlace(
    id: 'salalah_55coffee',
    govKey: 'dhofar',
    nameAr: 'Fifty Five كوفي',
    nameEn: 'Fifty Five Coffee',
    descriptionAr: 'كوفي مختص بإطلالة جميلة وأجواء مميزة في صلالة.',
    descriptionEn: 'Specialty coffee shop with a beautiful view in Salalah.',
    imageAsset: 'assets/places/salalah/55coffee.jpg',
    location: LatLng(17.0010976, 54.1054716),
    category: GovPlaceCategory.cafe,
    instagramUrl: 'https://www.instagram.com/55_coffee/',
    rating: 4.7,
  ),
];
