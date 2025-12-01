// lib/models/trip_hotel_item.dart

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// موديل الفندق اللي نستخدمه في صفحة الفنادق و "رحلتي"

class TripHotelItem {
  final String id;

  final String nameAr;

  final String nameEn;

  final String descAr;

  final String descEn;

  final String priceAr;

  final String priceEn;

  final String imgAsset;

  /// مفتاح المحافظة (نستخدمه للفلترة)

  /// مثال: Muscat, Dhofar, SouthSharqiyah ...

  final String cityKey;

  /// إحداثيات الفندق

  final double lat;

  final double lng;

  /// مفضلة أو لا

  bool isFav;

  TripHotelItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descAr,
    required this.descEn,
    required this.priceAr,
    required this.priceEn,
    required this.imgAsset,
    required this.cityKey,
    required this.lat,
    required this.lng,
    this.isFav = false,
  });

  LatLng get location => LatLng(lat, lng);
}

/// ✅ قائمة الفنادق الأساسية اللي تظهر في صفحة الفنادق

final List<TripHotelItem> kHotelsList = [
  TripHotelItem(
    id: 'sheraton_oman',
    nameAr: 'فندق شيراتون عمان',
    nameEn: 'Sheraton Oman Hotel',
    descAr: 'فندق خمس نجوم في قلب مسقط بالقرب من مطرح.',
    descEn: '5-star hotel in the heart of Muscat, near Muttrah.',
    priceAr: 'ابتداءً من 60 ر.ع',
    priceEn: 'From OMR 60',
    imgAsset: 'assets/hotels/sheraton.jpg',
    cityKey: 'Muscat',
    lat: 23.6135,
    lng: 58.5440,
  ),

  TripHotelItem(
    id: 'shangrila_barr_al_jissah',
    nameAr: 'منتجع شانغريلا بر الجصة',
    nameEn: 'Shangri-La Barr Al Jissah',
    descAr: 'منتجع فاخر بإطلالة بحرية رائعة في مسقط.',
    descEn: 'Luxury resort with stunning sea views in Muscat.',
    priceAr: 'ابتداءً من 75 ر.ع',
    priceEn: 'From OMR 75',
    imgAsset: 'assets/hotels/shangrila.jpg',
    cityKey: 'Muscat',
    lat: 23.5329,
    lng: 58.6607,
  ),

  TripHotelItem(
    id: 'radisson_collection_muscat',
    nameAr: 'راديسون كوليكشن مسقط',
    nameEn: 'Radisson Collection Hotel, Muscat',
    descAr: 'فندق راقٍ في مسقط مع خدمات ممتازة.',
    descEn: 'Premium hotel in Muscat with excellent service.',
    priceAr: 'ابتداءً من 55 ر.ع',
    priceEn: 'From OMR 55',
    imgAsset: 'assets/hotels/radisson.jpg',
    cityKey: 'Muscat',
    lat: 23.5850,
    lng: 58.4070,
  ),

  // تقدري تضيفي فنادق أخرى لنزوى / صلالة ... بنفس الشكل
];

/// ✅ قائمة الفنادق التي أضافتها المستخدِمة إلى رحلتها

///

/// نضيف فيها من صفحة الفنادق:

///   kTripHotels.add(hotel);

final List<TripHotelItem> kTripHotels = [];
