// lib/screens/your_trip_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/prefs.dart';

import '../widgets/trip_summary_card.dart';

// نستورد موديل الرحلة + قائمة الخطط + اسم الرحلة وعدد الأيام

import 'map_gmaps_screen.dart'
    show MapTripPlan, kTripPlans, kTripName, kTripDays, kTripStartDate;

import '../models/trip_hotel_item.dart' show TripHotelItem, kTripHotels;

import '../models/trip_attraction_item.dart'
    show TripAttractionItem, kTripAttractions;

class YourTripScreen extends StatefulWidget {
  final List<MapTripPlan> plans;

  const YourTripScreen({
    super.key,
    required this.plans,
  });

  @override
  State<YourTripScreen> createState() => _YourTripScreenState();
}

class _YourTripScreenState extends State<YourTripScreen> {
  double? _userLat;

  double? _userLng;

  bool get _hasPlaces => widget.plans.isNotEmpty;

  bool get _hasHotels => kTripHotels.isNotEmpty;

  bool get _hasAttractions => kTripAttractions.isNotEmpty;

  @override
  void initState() {
    super.initState();

    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    final sp = await Prefs.raw;

    setState(() {
      _userLat = sp.getDouble('user_lat');

      _userLng = sp.getDouble('user_lng');
    });
  }

  // حساب المسافة بالكيلومتر بين نقطتين (هفرسين)

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // km

    final dLat = _deg2rad(lat2 - lat1);

    final dLon = _deg2rad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _deg2rad(double deg) => deg * math.pi / 180.0;

  @override
  Widget build(BuildContext context) {
    final isEmpty = !_hasPlaces && !_hasHotels && !_hasAttractions;

    if (isEmpty) {
      // حالة ما فيه أي خطة – تصميم شبيه Visit Dubai

      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'الرحلات',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          centerTitle: true,
        ),
        body: const _EmptyTripView(),
      );
    }

    // تجميع الأماكن حسب اليوم

    final Map<int, List<MapTripPlan>> plansByDay = {};

    for (final p in widget.plans) {
      final d = p.day;

      plansByDay.putIfAbsent(d, () => []).add(p);
    }

    final days = plansByDay.keys.toList()..sort();

    // معلومات ملخص الرحلة

    final tripTitle = kTripName ?? 'رحلتي';

    final daysCount = kTripDays;

    final placesCount = widget.plans.length;

    final headerImageAsset =
        widget.plans.isNotEmpty ? widget.plans.first.place.imageAsset : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'رحلاتي / My Trips',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ====== كرت ملخص الرحلة (نفس فكرة Visit Dubai) ======

          TripSummaryCard(
            title: tripTitle,
            daysCount: daysCount,
            placesCount: placesCount,
            headerImageAsset:
                headerImageAsset ?? 'assets/places/default_header.jpg',
          ),

          const SizedBox(height: 20),

          // ====== الأيام والأماكن ======

          ...days.map(
            (d) => _buildDaySection(
              dayNumber: d,
              plans: plansByDay[d]!,
            ),
          ),

          const SizedBox(height: 24),

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

  // ---------- سيكشن اليوم ----------

  Widget _buildDaySection({
    required int dayNumber,
    required List<MapTripPlan> plans,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        title: Text(
          'اليوم $dayNumber',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${plans.length} موقع',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
          ),
        ),
        children: plans.map(_buildPlaceCard).toList(),
      ),
    );
  }

  // ---------- كرت المكان ----------

  Widget _buildPlaceCard(MapTripPlan plan) {
    final place = plan.place;

    double? distanceKm;

    if (_userLat != null && _userLng != null) {
      distanceKm = _distanceKm(
        _userLat!,
        _userLng!,
        place.position.latitude,
        place.position.longitude,
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1.5,
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
            const SizedBox(height: 2),
            Text(
              place.nameEn,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            if (distanceKm != null) ...[
              Text(
                '📍 المسافة: ${distanceKm.toStringAsFixed(1)} كم',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              '⏱ المدة المقترحة: ${plan.durationText}',
              style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- كرت الفندق ----------

  Widget _buildHotelCard(TripHotelItem h) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
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
                  Text(
                    h.nameEn,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
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
                  Text(
                    a.nameEn,
                    style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
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

// ================== شاشة لو ما في خطط (تصميم شبيه Visit Dubai) ==================

class _EmptyTripView extends StatelessWidget {
  const _EmptyTripView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // الهيدر (العنوان + التبويبات)

          const Align(
            alignment: Alignment.centerRight,
            child: Text(
              'الرحلات',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const [
              _TripsTab(text: 'الدليل', selected: false),
              SizedBox(width: 16),
              _TripsTab(text: 'الرحلات الموصى بها', selected: false),
              SizedBox(width: 16),
              _TripsTab(text: 'رحلاتي', selected: true),
            ],
          ),

          const SizedBox(height: 32),

          // صورة توضيحية (حطي أي صورة تحبينها)

          SizedBox(
            height: 220,
            child: Image.asset(
              'assets/places/my_trip_empty.jpg', // عدّلي المسار

              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 24),

          const _FeatureRow(
            icon: Icons.add,
            text: 'حفظ الوجهات التي ترغب بزيارتها',
          ),

          const SizedBox(height: 12),

          const _FeatureRow(
            icon: Icons.date_range,
            text: 'خطط لرحلتك على مدار عدة أيام',
          ),

          const SizedBox(height: 12),

          const _FeatureRow(
            icon: Icons.work_outline,
            text: 'الوصول إلى الرحلات من أي مكان في التطبيق',
          ),

          const SizedBox(height: 32),

          // زر إنشاء رحلة جديدة → يفتح الخريطة / المحافظات

          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                // هنا افتحي شاشة الخريطة اللي فيها Add to trip

                // غيّري '/map' لاسم الروت الصحيح عندك

                Navigator.pushNamed(context, '/map');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0067B9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إنشاء رحلة جديدة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// تبويب بسيط (رحلاتي – الدليل – الرحلات الموصى بها)

class _TripsTab extends StatelessWidget {
  final String text;

  final bool selected;

  const _TripsTab({
    required this.text,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 13,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected ? const Color(0xFFe91e63) : Colors.grey.shade500,
      ),
    );
  }
}

// سطر ميزة مع أيقونة

class _FeatureRow extends StatelessWidget {
  final IconData icon;

  final String text;

  const _FeatureRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, size: 20, color: Colors.grey.shade800),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
