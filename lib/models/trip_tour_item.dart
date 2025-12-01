// lib/models/trip_tour_item.dart

class TripTourItem {
  final String id;

  final String nameAr;

  final String nameEn;

  final String shortAr;

  final String shortEn;

  /// فئة / نوع الرحلة: adventure, nature, sport, culture ...

  final String categoryKey;

  final String locationAr;

  final String locationEn;

  final String imgAsset;

  /// رابط صفحة المعلومات (visitoman.om/ar/tours أو رابط رحلة محددة)

  final String infoUrl;

  /// رابط الحجز (booknow.visitoman.om/?tripType=ONLY_TICKET)

  final String bookingUrl;

  bool isFav;

  TripTourItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.shortAr,
    required this.shortEn,
    required this.categoryKey,
    required this.locationAr,
    required this.locationEn,
    required this.imgAsset,
    required this.infoUrl,
    required this.bookingUrl,
    this.isFav = false,
  });
}

/// قائمة كل الرحلات اللي بتعرضيها في الشاشة

final List<TripTourItem> kToursList = [
  TripTourItem(
    id: 'tour1',

    nameAr: 'الجولات بالمروحية',

    nameEn: 'Helicopter Tours',

    shortAr: 'حلقي في السماء واستمتعي بإطلالة على مسقط.',

    shortEn: 'Fly above Muscat with stunning aerial views.',

    categoryKey: 'adventure',

    locationAr: 'مسقط',

    locationEn: 'Muscat',

    imgAsset: 'assets/tours/helicopter.jpg',

    infoUrl: 'https://visitoman.om/ar/heliCopter-tours', // عدليها لو لزم

    bookingUrl: 'https://booknow.visitoman.om/?tripType=ONLY_TICKET',
  ),
  TripTourItem(
    id: 'tour2',
    nameAr: 'سفينة الدهو التقليدية',
    nameEn: 'Dhow Cruise',
    shortAr: 'رحلة بحرية هادئة مع غروب الشمس.',
    shortEn: 'Relaxing dhow cruise with sunset views.',
    categoryKey: 'nature',
    locationAr: 'مسقط / مطرح',
    locationEn: 'Muscat / Muttrah',
    imgAsset: 'assets/tours/dhow.jpg',
    infoUrl: 'https://visitoman.om/ar/tours',
    bookingUrl: 'https://booknow.visitoman.om/?tripType=ONLY_TICKET',
  ),
  TripTourItem(
    id: 'tour3',
    nameAr: 'مغامرات الصحراء',
    nameEn: 'Desert Adventure',
    shortAr: 'تجربة التخييم وركوب السيارات في الرمال.',
    shortEn: 'Camping & dune bashing in the desert.',
    categoryKey: 'adventure',
    locationAr: 'الشرقية / بدية',
    locationEn: 'Sharqiyah / Bidiyah',
    imgAsset: 'assets/tours/desert.jpg',
    infoUrl: 'https://visitoman.om/ar/tours',
    bookingUrl: 'https://booknow.visitoman.om/?tripType=ONLY_TICKET',
  ),
  TripTourItem(
    id: 'tour4',
    nameAr: 'الطبيعة والحياة الفطرية',
    nameEn: 'Nature & Wildlife',
    shortAr: 'استمتعي بالشواطئ والحياة البحرية والجبال.',
    shortEn: 'Discover beaches, marine life and mountains.',
    categoryKey: 'nature',
    locationAr: 'ظفار وغيرها',
    locationEn: 'Dhofar & more',
    imgAsset: 'assets/tours/nature.jpg',
    infoUrl: 'https://visitoman.om/ar/tours',
    bookingUrl: 'https://booknow.visitoman.om/?tripType=ONLY_TICKET',
  ),
];

/// قائمة الرحلات المضافة إلى "رحلتي"

final List<TripTourItem> kTripTours = [];
