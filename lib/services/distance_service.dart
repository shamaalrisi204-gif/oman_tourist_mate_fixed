// lib/services/distance_service.dart
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DriveETA {
  final int durationMinutes; // وقت القيادة بالدقائق
  final double distanceKm; // المسافة بالكيلومتر
  final String rawTextDuration;
  final String rawTextDistance;
  const DriveETA({
    required this.durationMinutes,
    required this.distanceKm,
    required this.rawTextDuration,
    required this.rawTextDistance,
  });
}

class DistanceService {
  /// يستدعي Distance Matrix API
  static Future<DriveETA?> getDriveEta({
    required LatLng origin,
    required LatLng destination,
    required String apiKey,
    String language = 'ar',
  }) async {
    final uri = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?origins=${origin.latitude},${origin.longitude}'
      '&destinations=${destination.latitude},${destination.longitude}'
      '&mode=driving&departure_time=now'
      '&language=$language'
      '&key=$apiKey',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return null;
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (body['status'] != 'OK') return null;
    final rows = body['rows'] as List?;
    if (rows == null || rows.isEmpty) return null;
    final elements = rows.first['elements'] as List?;
    if (elements == null || elements.isEmpty) return null;
    final el = elements.first as Map<String, dynamic>;
    if (el['status'] != 'OK') return null;
    // إذا كان عندك traffic, يجيك duration_in_traffic
    final duration = (el['duration_in_traffic'] ?? el['duration']) as Map?;
    final distance = el['distance'] as Map?;
    final minutes = ((duration?['value'] ?? 0) as num) ~/ 60;
    final km = ((distance?['value'] ?? 0) as num) / 1000.0;
    return DriveETA(
      durationMinutes: minutes,
      distanceKm: km.toDouble(),
      rawTextDuration: (duration?['text'] ?? '').toString(),
      rawTextDistance: (distance?['text'] ?? '').toString(),
    );
  }
}
