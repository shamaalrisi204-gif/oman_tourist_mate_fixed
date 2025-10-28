// lib/models/trip_plan.dart
class TripPlan {
  final String category; // sea | desert | historic
  final String placeName;
  final String placeCity;
  final String stayCity;
  final bool willBookHere;
  final int hours;
  final int etaMinutes; // مدة القيادة بالدقائق (من واجهة الخريطة)
  final String suggestedHotel;
  final String suggestedRestaurant;
  TripPlan({
    required this.category,
    required this.placeName,
    required this.placeCity,
    required this.stayCity,
    required this.willBookHere,
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
        'hours': hours,
        'etaMinutes': etaMinutes,
        'suggestedHotel': suggestedHotel,
        'suggestedRestaurant': suggestedRestaurant,
      };
  factory TripPlan.fromJson(Map<String, dynamic> j) => TripPlan(
        category: j['category'] as String,
        placeName: j['placeName'] as String,
        placeCity: j['placeCity'] as String,
        stayCity: j['stayCity'] as String,
        willBookHere: j['willBookHere'] as bool? ?? false,
        hours: j['hours'] as int? ?? 0,
        etaMinutes: j['etaMinutes'] as int? ?? 0,
        suggestedHotel: j['suggestedHotel'] as String? ?? '',
        suggestedRestaurant: j['suggestedRestaurant'] as String? ?? '',
      );
}
