import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DirectionsResult {
  final int distanceMeters;
  final int durationSeconds;
  DirectionsResult(
      {required this.distanceMeters, required this.durationSeconds});
}

class DirectionsService {
  // مرّري المفتاح في التشغيل:
  // flutter run --dart-define=GOOGLE_MAPS_WEB_SERVICE_KEY=AIzaSy...
  static const _apiKey = String.fromEnvironment('GOOGLE_MAPS_WEB_SERVICE_KEY');
  static Future<DirectionsResult?> driving(LatLng from, LatLng to) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${from.latitude},${from.longitude}'
      '&destination=${to.latitude},${to.longitude}'
      '&mode=driving'
      '&key=$_apiKey',
    );
    final res = await http.get(url);
    if (res.statusCode != 200) return null;
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (data['status'] != 'OK') return null;
    final route = (data['routes'] as List).first;
    final leg = (route['legs'] as List).first;
    final distance = (leg['distance']['value'] as num).toInt();
    final duration = (leg['duration']['value'] as num).toInt();
    return DirectionsResult(
        distanceMeters: distance, durationSeconds: duration);
  }
}
