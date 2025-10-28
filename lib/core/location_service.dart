// lib/core/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// يطلب الإذن ويعيد الإحداثيات الحالية
  static Future<Position> getCurrentPosition() async {
    // تأكد أن خدمة الموقع مفعلة
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'خدمة تحديد الموقع متوقفة. فعّل الـ GPS من الإعدادات.';
    }
    // تحقق من الإذن واطلبه عند الحاجة
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw 'تم رفض إذن الموقع.';
    }
    if (permission == LocationPermission.deniedForever) {
      throw 'رفض دائم لإذن الموقع. افتح الإعدادات وامنح الإذن للتطبيق.';
    }
    // ارجاع الإحداثيات
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// reverse geocoding: يحوّل الإحداثيات إلى اسم مدينة/منطقة
  static Future<String> reverseCity(double lat, double lng) async {
    final placemarks = await placemarkFromCoordinates(lat, lng);
    if (placemarks.isEmpty) return 'غير معروف';
    final p = placemarks.first;
    // جرّب locality ثم administrativeArea
    return (p.locality?.isNotEmpty == true
            ? p.locality
            : p.administrativeArea) ??
        'غير معروف';
  }
}
