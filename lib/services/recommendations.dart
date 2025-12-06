// lib/services/recommendations.dart

import '../models/trip_plan.dart';

/// يبني خطة جاهزة من بيانات المستخدم.
///
/// مخلّي أغلب الباراميترات اختيارية مع قيم افتراضية عشان ما يعطيك Missing required argument.
class Recommendations {
  static TripPlanModel buildTrip({
    // ✨ هذا الوحيد الإجباري (مدينة الإقامة)
    required String stayCity,

    // ✨ الباقي اختياري مع قيم افتراضية مريحة
    String category = 'sea', // sea | desert | historic | mountain | ...

    String placeName = '',
    String placeCity = '',
    bool willBookHere = false,
    int days = 1, // عدد الأيام الافتراضي
    int hours = 0, // عدد الساعات في المكان
    int etaMinutes = 0, // مدة القيادة بالدقائق

    String suggestedHotel = '',
    String suggestedRestaurant = '',
  }) {
    return TripPlanModel(
      category: category,
      placeName: placeName,
      placeCity: placeCity,
      stayCity: stayCity,
      willBookHere: willBookHere,
      days: days,
      hours: hours,
      etaMinutes: etaMinutes,
      suggestedHotel: suggestedHotel,
      suggestedRestaurant: suggestedRestaurant,
    );
  }
}
