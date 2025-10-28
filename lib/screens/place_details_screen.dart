import 'package:flutter/material.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final String governorate;
  final String placeName;
  final double lat;
  final double lng;
  const PlaceDetailsScreen({
    super.key,
    required this.governorate,
    required this.placeName,
    required this.lat,
    required this.lng,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(placeName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "المحافظة: $governorate",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "المكان: $placeName",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text("📍 الإحداثيات:"),
            Text("Latitude: $lat"),
            Text("Longitude: $lng"),
          ],
        ),
      ),
    );
  }
}
