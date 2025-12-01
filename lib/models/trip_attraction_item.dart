// lib/models/trip_attraction_item.dart

class TripAttractionItem {
  final String id;

  final String cityKey; // مثل: Muscat, Dhofar ..

  final String nameAr;

  final String nameEn;

  final String imgAsset;

  final String descAr;

  final String descEn;

  final String moreUrl;

  final double lat;

  final double lng;

  bool isFav; // للمفضلة (القلب)

  TripAttractionItem({
    required this.id,
    required this.cityKey,
    required this.nameAr,
    required this.nameEn,
    required this.imgAsset,
    required this.descAr,
    required this.descEn,
    required this.moreUrl,
    required this.lat,
    required this.lng,
    this.isFav = false,
  });
}

/// قائمة كل المعالم (تقدر تزيدي عليها)

final List<TripAttractionItem> kAttractionsList = [
  TripAttractionItem(
    id: 'nat-museum',
    cityKey: 'Muscat',
    nameAr: 'المتحف الوطني',
    nameEn: 'National Museum of Oman',
    imgAsset: 'assets/attractions/national_museum.jpg',
    descAr:
        'متحف حديث يعرّفك على التاريخ والحضارة العُمانية عبر معروضات مميّزة.',
    descEn: 'A modern museum that showcases Oman’s rich history and culture.',
    moreUrl: 'https://visitoman.om/ar/attractions',
    lat: 23.6157,
    lng: 58.5933,
  ),
  TripAttractionItem(
    id: 'royal-opera',
    cityKey: 'Muscat',
    nameAr: 'دار الأوبرا السلطانية',
    nameEn: 'Royal Opera House Muscat',
    imgAsset: 'assets/attractions/opera_house.jpg',
    descAr: 'أيقونة ثقافية وفنية تستضيف عروضاً عالمية وتُعد من أهم معالم مسقط.',
    descEn: 'A cultural landmark hosting world-class performances in Muscat.',
    moreUrl: 'https://visitoman.om/ar/attractions',
    lat: 23.6085,
    lng: 58.4442,
  ),
  TripAttractionItem(
    id: 'al-hoota',
    cityKey: 'Dakhiliyah',
    nameAr: 'كهف الهوتة',
    nameEn: 'Al Hoota Cave',
    imgAsset: 'assets/attractions/al_hoota_cave.jpg',
    descAr:
        'كهف طبيعي مدهش يمكن الوصول إليه عبر قطار صغير وتجربة ممتعة تحت الأرض.',
    descEn:
        'A stunning natural cave reached by a small train and guided tours.',
    moreUrl: 'https://visitoman.om/ar/attractions',
    lat: 22.8331,
    lng: 57.3747,
  ),
];

/// المعالم المضافة إلى "رحلتي"

final List<TripAttractionItem> kTripAttractions = [];
