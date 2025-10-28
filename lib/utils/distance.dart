// lib/utils/distance.dart
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Distance {
  /// مسافة هافرسين بالكيلومتر
  static double haversineKm(LatLng a, LatLng b) {
    const r = 6371.0; // km
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final la1 = _deg2rad(a.latitude);
    final la2 = _deg2rad(b.latitude);
    final s = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(la1) * cos(la2);
    final c = 2 * atan2(sqrt(s), sqrt(1 - s));
    return r * c;
  }

  /// تقدير زمن القيادة بسرعة متوسطة 70 كم/س
  static String estimateDriveTime(double km) {
    final hours = km / 70.0;
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    if (h == 0) return '$m دقيقة';
    return '$h ساعة ${m == 0 ? '' : '$m دقيقة'}'.trim();
  }

  static double _deg2rad(double d) => d * pi / 180.0;
}
