import 'dart:convert';

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/prefs.dart';

import '../widgets/trip_summary_card.dart';

import 'map_gmaps_screen.dart' show MapTripPlan, kTripName, kTripDays;

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
  static const _green = Color(0xFF174D40);

  static const _darkGreen = Color(0xFF08362D);

  static const _gold = Color(0xFFD9BA7A);

  static const _cream = Color(0xFFFFFAF3);

  // منفصل تماماً عن favorites_list_v1

  static const _savedPlacesKey = 'my_trip_saved_places_v1';

  double? _userLat;

  double? _userLng;

  int _selectedTab = 0;

  bool _loading = true;

  List<_SavedTripPlace> _savedPlaces = [];

  bool get _hasPlans =>
      widget.plans.isNotEmpty ||
      kTripHotels.isNotEmpty ||
      kTripAttractions.isNotEmpty;

  @override
  void initState() {
    super.initState();

    _loadUserLocation();

    _loadSavedPlaces();
  }

  Future<void> _loadUserLocation() async {
    final sp = await Prefs.raw;

    if (!mounted) return;

    setState(() {
      _userLat = sp.getDouble('user_lat');

      _userLng = sp.getDouble('user_lng');
    });
  }

  Future<void> _loadSavedPlaces() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getStringList(_savedPlacesKey) ?? [];

    final places = <_SavedTripPlace>[];

    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is Map<String, dynamic>) {
          places.add(_SavedTripPlace.fromJson(decoded));
        }
      } catch (_) {
        // تجاهل السجلات غير الصالحة
      }
    }

    if (!mounted) return;

    setState(() {
      _savedPlaces = places;

      _loading = false;
    });
  }

  Future<void> _persistSavedPlaces() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _savedPlacesKey,
      _savedPlaces.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> _addPlaceDialog() async {
    final nameController = TextEditingController();

    final locationController = TextEditingController();

    final result = await showDialog<_SavedTripPlace>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _cream,
        title: const Text(
          'إضافة مكان إلى رحلتي',
          style: TextStyle(
            fontFamily: 'Tajawal',
            color: _green,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'اسم المكان',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'الموقع أو المحافظة (اختياري)',
                prefixIcon: Icon(Icons.map_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _green,
            ),
            onPressed: () {
              final name = nameController.text.trim();

              if (name.isEmpty) return;

              Navigator.pop(
                dialogContext,
                _SavedTripPlace(
                  id: DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name,
                  location: locationController.text.trim(),
                  savedAt: DateTime.now(),
                ),
              );
            },
            child: const Text('حفظ المكان'),
          ),
        ],
      ),
    );

    nameController.dispose();

    locationController.dispose();

    if (result == null || !mounted) return;

    setState(() {
      _savedPlaces.insert(0, result);
    });

    await _persistSavedPlaces();
  }

  Future<void> _removePlace(_SavedTripPlace place) async {
    setState(() {
      _savedPlaces.removeWhere((p) => p.id == place.id);
    });

    await _persistSavedPlaces();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حذف ${place.name} من رحلتي'),
      ),
    );
  }

  double _deg2rad(double value) => value * math.pi / 180;

  double _distanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0;

    final dLat = _deg2rad(lat2 - lat1);

    final dLon = _deg2rad(lon2 - lon1);

    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.pow(math.sin(dLon / 2), 2);

    final c = 2 *
        math.atan2(
          math.sqrt(a),
          math.sqrt(math.max(0, 1 - a)),
        );

    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,
        appBar: AppBar(
          backgroundColor: _cream,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'رحلتي',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              color: _green,
              fontSize: 21,
            ),
          ),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: _green,
            ),
          ),
        ),
        body: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _green,
                      ),
                    )
                  : _buildSelectedTab(),
            ),
          ],
        ),
        bottomNavigationBar: _selectedTab == 0
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    14,
                  ),
                  child: SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _addPlaceDialog,
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text(
                        'إضافة مكان جديد',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 22,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_green, _darkGreen],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _gold,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.travel_explore,
            color: _gold,
            size: 35,
          ),
          const SizedBox(height: 8),
          const Text(
            'رحلتي في عُمان',
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'احتفظ بوجهاتك ونظّم مغامراتك القادمة',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      ('أماكني المحفوظة', Icons.bookmark_outline),
      ('خططي', Icons.route_outlined),
      ('رحلات سابقة', Icons.history),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTab == index;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedTab = index);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _green : const Color(0xFFF1E6D4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? _gold : Colors.transparent,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tabs[index].$2,
                        size: 22,
                        color: selected ? _gold : _green,
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          tabs[index].$1,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : _green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedTab) {
      case 0:
        return _buildSavedPlacesTab();

      case 1:
        return _buildPlansTab();

      default:
        return _buildPreviousTripsTab();
    }
  }

  Widget _buildSavedPlacesTab() {
    if (_savedPlaces.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_add_outlined,
        title: 'لا توجد أماكن محفوظة بعد',
        description: 'أضف الأماكن التي ترغب بزيارتها وستظهر هنا.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle(
          'أماكني المحفوظة',
          '${_savedPlaces.length} مكان',
        ),
        const SizedBox(height: 12),
        ..._savedPlaces.map(_buildSavedPlaceCard),
      ],
    );
  }

  Widget _buildSavedPlaceCard(_SavedTripPlace place) {
    final date = place.savedAt;

    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _gold.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFF1E6D4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.landscape_outlined,
                color: _green,
                size: 36,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: _green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (place.location.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      place.location,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    'تم الحفظ: $formattedDate',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.black45,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: _green,
              ),
              onSelected: (value) {
                if (value == 'delete') {
                  _removePlace(place);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('إزالة من رحلتي'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansTab() {
    if (!_hasPlans) {
      return _buildEmptyState(
        icon: Icons.route_outlined,
        title: 'لا توجد خطط رحلات بعد',
        description: 'أنشئ خطة من الخريطة وستظهر تفاصيلها هنا.',
      );
    }

    final plansByDay = <int, List<MapTripPlan>>{};

    for (final plan in widget.plans) {
      plansByDay.putIfAbsent(plan.day, () => []).add(plan);
    }

    final days = plansByDay.keys.toList()..sort();

    final headerImage = widget.plans.isNotEmpty
        ? widget.plans.first.place.imageAsset
        : 'assets/places/default_header.jpg';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TripSummaryCard(
          title: kTripName ?? 'رحلتي',
          daysCount: kTripDays,
          placesCount: widget.plans.length,
          headerImageAsset: headerImage,
        ),
        const SizedBox(height: 18),
        ...days.map(
          (day) => _buildDaySection(
            dayNumber: day,
            plans: plansByDay[day]!,
          ),
        ),
        if (kTripHotels.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionTitle('أماكن الإقامة', ''),
          const SizedBox(height: 8),
          ...kTripHotels.map(_buildHotelCard),
        ],
        if (kTripAttractions.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionTitle('المعالم السياحية', ''),
          const SizedBox(height: 8),
          ...kTripAttractions.map(_buildAttractionCard),
        ],
      ],
    );
  }

  Widget _buildDaySection({
    required int dayNumber,
    required List<MapTripPlan> plans,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _gold),
      ),
      child: ExpansionTile(
        iconColor: _green,
        title: Text(
          'اليوم $dayNumber',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
        subtitle: Text(
          '${plans.length} موقع',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        children: plans.map(_buildPlaceCard).toList(),
      ),
    );
  }

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

    return ListTile(
      title: Text(
        place.nameAr,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            place.nameEn,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          if (distanceKm != null)
            Text(
              'المسافة: ${distanceKm.toStringAsFixed(1)} كم',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          Text(
            'المدة المقترحة: ${plan.durationText}',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
        ],
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          place.imageAsset,
          width: 55,
          height: 55,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.place_outlined,
            color: _green,
          ),
        ),
      ),
    );
  }

  Widget _buildHotelCard(TripHotelItem hotel) {
    return _buildImageInfoCard(
      title: hotel.nameAr,
      subtitle: hotel.nameEn,
      imageAsset: hotel.imgAsset,
    );
  }

  Widget _buildAttractionCard(TripAttractionItem attraction) {
    return _buildImageInfoCard(
      title: attraction.nameAr,
      subtitle: attraction.nameEn,
      imageAsset: attraction.imgAsset,
    );
  }

  Widget _buildImageInfoCard({
    required String title,
    required String subtitle,
    required String imageAsset,
  }) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _gold),
      ),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            imageAsset,
            width: 65,
            height: 65,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.image_outlined,
              color: _green,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            color: _green,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  Widget _buildPreviousTripsTab() {
    return _buildEmptyState(
      icon: Icons.history,
      title: 'لا توجد رحلات سابقة',
      description: 'ستظهر رحلاتك السابقة هنا عند إضافة سجل للرحلات المكتملة.',
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: const Color(0xFFF1E6D4),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                icon,
                color: _green,
                size: 52,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: _green,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String count) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: _green,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (count.isNotEmpty)
          Text(
            count,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

class _SavedTripPlace {
  final String id;

  final String name;

  final String location;

  final DateTime savedAt;

  const _SavedTripPlace({
    required this.id,
    required this.name,
    required this.location,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory _SavedTripPlace.fromJson(
    Map<String, dynamic> json,
  ) {
    return _SavedTripPlace(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      savedAt: DateTime.tryParse(
            json['savedAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
