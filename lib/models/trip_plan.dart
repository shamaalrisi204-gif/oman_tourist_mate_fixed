// lib/models/trip_plan.dart

class MapTripPlan {
  final String category;

  final String placeName;

  final String placeCity;

  final String stayCity;

  final bool willBookHere;

  final int days; // كم يوم مخصص له

  final int hours; // كم ساعة في هذا المكان

  final int etaMinutes; // زمن الوصول التقريبي

  final String suggestedHotel;

  final String suggestedRestaurant;

  MapTripPlan({
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

/// عنصر واحد داخل يوم (مكان معيّن في اليوم)

class TripPlanItem {
  final MapTripPlan mapPlan;

  TripPlanItem({required this.mapPlan});

  Map<String, dynamic> toJson() => {
        'mapPlan': mapPlan.toJson(),
      };
}

/// يوم واحد من الرحلة (Day 1, Day 2, ...)

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

/// الخطة الكاملة

class TripPlan {
  final String city; // المدينة الأساسية (مسقط، صلالة...)

  final int totalDays; // عدد الأيام

  final List<TripPlanDay> days;

  TripPlan({
    required this.city,
    required this.totalDays,
    required this.days,
  });
}
