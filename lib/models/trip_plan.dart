// lib/models/trip_plan.dart

class MapTripPlan {
  final String category;

  final String placeName;

  final String placeCity;

  final String stayCity;

  final bool willBookHere;

  final int days; // <-- تمت إضافتها

  final int hours; // <-- ساعات داخل المكان

  final int etaMinutes;

  final String suggestedHotel;

  final String suggestedRestaurant;

  MapTripPlan({
    required this.category,
    required this.placeName,
    required this.placeCity,
    required this.stayCity,
    required this.willBookHere,
    required this.days, // <-- مهم

    required this.hours,
    required this.etaMinutes,
    required this.suggestedHotel,
    required this.suggestedRestaurant,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'placeName': placeName,
        'placeCity': placeCity,
        'stayCity': stayCity,
        'willBookHere': willBookHere,
        'days': days,
        'hours': hours,
        'etaMinutes': etaMinutes,
        'suggestedHotel': suggestedHotel,
        'suggestedRestaurant': suggestedRestaurant,
      };

  factory MapTripPlan.fromJson(Map<String, dynamic> j) => MapTripPlan(
        category: j['category'] ?? '',
        placeName: j['placeName'] ?? '',
        placeCity: j['placeCity'] ?? '',
        stayCity: j['stayCity'] ?? '',
        willBookHere: j['willBookHere'] ?? false,
        days: j['days'] ?? 1,
        hours: j['hours'] ?? 0,
        etaMinutes: j['etaMinutes'] ?? 0,
        suggestedHotel: j['suggestedHotel'] ?? '',
        suggestedRestaurant: j['suggestedRestaurant'] ?? '',
      );
}
