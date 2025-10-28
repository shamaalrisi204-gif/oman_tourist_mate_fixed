// lib/services/recommendations.dart
import '../models/trip_plan.dart';

/// يبني خطة جاهزة بالحقول المطلوبة من TripPlan
class Recommendations {
  static TripPlan buildTrip({
    // المطلوبة
    required String category, // 'sea' | 'desert' | 'historic'
    required String placeName, // اسم المكان المختار
    required String placeCity, // مدينة المكان
    required String stayCity, // مدينة السكن
    required bool willBookHere, // يحجز في نفس المكان أو لا
    required int hours, // عدد الساعات التي حدّدها المستخدم
    required int
        etaMinutes, // مدة القيادة بالدقائق (حقيقية من Distance Matrix أو تقديرك)
    // اختياري: لو ما توفر نعطي قيم افتراضية
    String suggestedHotel = 'Suggested hotel nearby',
    String suggestedRestaurant = 'Suggested restaurant nearby',
  }) {
    return TripPlan(
      category: category,
      placeName: placeName,
      placeCity: placeCity,
      stayCity: stayCity,
      willBookHere: willBookHere,
      hours: hours,
      etaMinutes: etaMinutes,
      suggestedHotel: suggestedHotel,
      suggestedRestaurant: suggestedRestaurant,
    );
  }
}
