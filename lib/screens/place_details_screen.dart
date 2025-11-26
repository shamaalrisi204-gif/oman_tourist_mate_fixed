// lib/screens/place_details_screen.dart

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> place;
  final bool isArabic;

  const PlaceDetailsScreen({
    super.key,
    required this.place,
    required this.isArabic,
  });

  String t(String ar, String en) => isArabic ? ar : en;

  Future<void> _openInMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // لو ما قدر يفتح الخرائط
      debugPrint('Could not open Google Maps');
    }
  }

  Widget _buildPlaceImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = isArabic ? place['nameAr'] : place['nameEn'];
    final desc =
        isArabic ? place['descriptionArShort'] : place['descriptionEnShort'];

    final imageUrl = place['imageUrl'] ?? '';
    final governorate = place['governorate'] ?? '';
    final city = place['city'] ?? '';

    final lat = (place['lat'] as num?)?.toDouble();
    final lng = (place['lng'] as num?)?.toDouble();

    final hasValidLocation =
        lat != null && lng != null && (lat != 0 || lng != 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          name,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // الصورة
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _buildPlaceImage(imageUrl),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '$governorate • $city',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              fontFamily: 'Tajawal',
            ),
          ),

          const SizedBox(height: 12),

          Text(
            desc,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              fontFamily: 'Tajawal',
            ),
          ),

          const SizedBox(height: 20),

          if (hasValidLocation) ...[
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 8),
                Text(
                  '($lat, $lng)',
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openInMaps(lat!, lng!),
                  icon: const Icon(Icons.map),
                  label: Text(
                    t('افتح في خرائط جوجل', 'Open in Google Maps'),
                    style: const TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // زر المشاركة
          Center(
            child: TextButton.icon(
              onPressed: () {
                final shareText =
                    '$name\n$desc\n${hasValidLocation ? "Location: $lat, $lng" : ""}';
                Share.share(shareText);
              },
              icon: const Icon(Icons.share),
              label: Text(
                t("مشاركة", "Share"),
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
