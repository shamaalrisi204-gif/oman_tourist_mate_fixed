// lib/models/trip_plan.dart

class TripPlanModel {
  final String category;
  final String placeName;
  final String placeCity;
  final String stayCity;
  final bool willBookHere;

  final int days;
  final int hours;
  final int etaMinutes;

  final String suggestedHotel;
  final String suggestedRestaurant;

  TripPlanModel({
    required this.category,
    required this.placeName,
    required this.placeCity,
    required this.stayCity,
    required this.willBookHere,
    required this.days,
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

  factory TripPlanModel.fromJson(Map<String, dynamic> j) => TripPlanModel(
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

/// عنصر داخل اليوم
class TripPlanItem {
  final TripPlanModel plan;
  TripPlanItem({required this.plan});

  Map<String, dynamic> toJson() => {
        'plan': plan.toJson(),
      };
}

/// يوم داخل الخطة
class TripPlanDay {
  final int dayNumber;
  final List<TripPlanItem> items;

  TripPlanDay({
    required this.dayNumber,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

/// خطة كاملة
class TripPlan {
  final String city;
  final int totalDays;
  final List<TripPlanDay> days;

  TripPlan({
    required this.city,
    required this.totalDays,
    required this.days,
  });
}
