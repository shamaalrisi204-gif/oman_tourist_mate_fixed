// lib/screens/your_trip_screen.dart

import 'package:flutter/material.dart';

import 'map_gmaps_screen.dart' show MapTripPlan, kTripPlans;

import '../models/trip_hotel_item.dart' show TripHotelItem, kTripHotels;

import '../models/trip_attraction_item.dart'
    show TripAttractionItem, kTripAttractions;

class YourTripScreen extends StatelessWidget {
  final List<MapTripPlan> plans;

  const YourTripScreen({
    super.key,
    required this.plans,
  });

  bool get _hasPlaces => plans.isNotEmpty;

  bool get _hasHotels => kTripHotels.isNotEmpty;

  bool get _hasAttractions => kTripAttractions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final isEmpty = !_hasPlaces && !_hasHotels && !_hasAttractions;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'رحلتي / My Trip',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
      ),
      body: isEmpty
          ? const _EmptyTripView()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_hasPlaces) ...[
                  const Text(
                    '📍 الأماكن التي ستزورينها',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...plans.map(_buildPlaceCard),
                  const SizedBox(height: 20),
                ],
                if (_hasHotels) ...[
                  const Text(
                    '🏨 أماكن الإقامة في رحلتك',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...kTripHotels.map(_buildHotelCard),
                  const SizedBox(height: 20),
                ],
                if (_hasAttractions) ...[
                  const Text(
                    '⭐ المعالم السياحية في خطتك',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...kTripAttractions.map(_buildAttractionCard),
                ],
              ],
            ),
    );
  }

  // ---------- كرت المكان من الخريطة ----------

  Widget _buildPlaceCard(MapTripPlan plan) {
    final place = plan.place;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.nameAr,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              place.nameEn,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⏱ المدة المقترحة: ${plan.durationText}',
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'التفضيلات في هذا المكان: '
              '${plan.wantHotels ? 'فنادق ✔ ' : ''}'
              '${plan.wantRestaurants ? 'مطاعم ✔ ' : ''}'
              '${plan.wantSittings ? 'جلسات ✔ ' : ''}',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- كرت الفندق في الرحلة ----------

  Widget _buildHotelCard(TripHotelItem h) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                h.imgAsset,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    h.nameAr,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    h.nameEn,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    h.descAr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '💰 ${h.priceAr}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- كرت المعلم السياحي ----------

  Widget _buildAttractionCard(TripAttractionItem a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                a.imgAsset,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.nameAr,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.nameEn,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.descAr,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- شاشة لو ما في خطط ----------

class _EmptyTripView extends StatelessWidget {
  const _EmptyTripView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'ما عندك خطط محفوظة حتى الآن.\n'
          '▪ من الخريطة: اختاري مكان واضغطي "تأكيد الخطة".\n'
          '▪ من صفحة الفنادق: اضغطي "أضف لرحلتي" عند الفندق المناسب.\n'
          '▪ من المعالم السياحية: اضغطي "أضف إلى رحلتي" عند المعلم المناسب.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
        ),
      ),
    );
  }
}
