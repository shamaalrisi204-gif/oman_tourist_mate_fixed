// lib/screens/map_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../core/secrets.dart';
import '../models/trip_plan.dart';
import 'trip_plan_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

/// نموذج مكان بسيط يستعمله تدفّق الأسئلة
class Place {
  final String id,
      nameAr,
      nameEn,
      cityAr,
      cityEn,
      category; // sea|historic|desert
  final LatLng pos;
  const Place({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.cityAr,
    required this.cityEn,
    required this.category,
    required this.pos,
  });
  String name(bool ar) => ar ? nameAr : nameEn;
  String city(bool ar) => ar ? cityAr : cityEn;
}

// أمثلة قليلة لتدفّق الأسئلة
const _places = <Place>[
  Place(
    id: 'sohar-beach',
    nameAr: 'شاطئ صحار',
    nameEn: 'Sohar Beach',
    cityAr: 'صحار',
    cityEn: 'Sohar',
    category: 'sea',
    pos: LatLng(24.3509, 56.7070),
  ),
  Place(
    id: 'nizwa-fort',
    nameAr: 'قلعة نزوى',
    nameEn: 'Nizwa Fort',
    cityAr: 'نزوى',
    cityEn: 'Nizwa',
    category: 'historic',
    pos: LatLng(22.9333, 57.5333),
  ),
  Place(
    id: 'wahiba',
    nameAr: 'رمال الشرقية',
    nameEn: 'Wahiba Sands',
    cityAr: 'الشرقية',
    cityEn: 'Ash Sharqiyah',
    category: 'desert',
    pos: LatLng(21.3778, 58.7498),
  ),
];

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _map;
  bool _isArabic = true;

  // حدود الكاميرا لعُمان (للزوم والـ pan)
  static final LatLngBounds _omanBounds = LatLngBounds(
    southwest: const LatLng(16.4, 52.0),
    northeast: const LatLng(26.6, 60.5),
  );

  static const CameraPosition _initial = CameraPosition(
    target: LatLng(23.6, 58.4),
    zoom: 6.3,
  );

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Polygon> _polygons = {}; // لو حبيتي لاحقًا تلوّنين المحافظات

  LatLng? _userLatLng;
  StreamSubscription<Position>? _locSub;

  BitmapDescriptor? _cityIcon;

  // مراكز مدن رئيسية (للعلامات)
  final Map<String, (LatLng center, String cityAr, String cityEn)>
      _cityCenters = {
    'Muscat': (const LatLng(23.5880, 58.3829), 'مسقط', 'Muscat'),
    'Sohar': (const LatLng(24.3500, 56.7300), 'صحار', 'Sohar'),
    'Nizwa': (const LatLng(22.9333, 57.5333), 'نزوى', 'Nizwa'),
    'Bahla': (const LatLng(22.9730, 57.3040), 'بهلاء', 'Bahla'),
    'Salalah': (const LatLng(17.0197, 54.0897), 'صلالة', 'Salalah'),
    'Sur': (const LatLng(22.5667, 59.5289), 'صور', 'Sur'),
    'Khasab': (const LatLng(26.1746, 56.2420), 'خصب', 'Khasab'),
    'Rustaq': (const LatLng(23.3900, 57.4244), 'الرستاق', 'Rustaq'),
  };

  /// معرض (مدينة -> فئة -> عناصر بعناوين وصور)
  /// مفعّل لصحار لأن صورها موجودة عندك حالياً.
  final Map<String, Map<String, List<Map<String, dynamic>>>> _gallery = {
    'Sohar': {
      'sea': [
        {
          'titleAr': 'شاطئ صحار',
          'titleEn': 'Sohar Beach',
          'photos': [
            'assets/places/sohar/beach_1.jpg',
            'assets/places/sohar/beach_2.jpg',
          ],
        },
      ],
      'historic': [
        {
          'titleAr': 'قلعة صحار',
          'titleEn': 'Sohar Fort',
          'photos': [
            'assets/places/sohar/fort_1.jpg',
            'assets/places/sohar/fort_2.jpg',
          ],
        },
      ],
      'desert': const [],
    },
    // مدن أخرى بدون صور حالياً — لا مشكلة
    'Muscat': {'sea': const [], 'historic': const [], 'desert': const []},
    'Nizwa': {'sea': const [], 'historic': const [], 'desert': const []},
    'Bahla': {'sea': const [], 'historic': const [], 'desert': const []},
    'Salalah': {'sea': const [], 'historic': const [], 'desert': const []},
    'Sur': {'sea': const [], 'historic': const [], 'desert': const []},
    'Khasab': {'sea': const [], 'historic': const [], 'desert': const []},
    'Rustaq': {'sea': const [], 'historic': const [], 'desert': const []},
  };

  @override
  void initState() {
    super.initState();
    _loadMarkerIcon().then((_) => _buildCityMarkers());
    _initLocation();
  }

  @override
  void dispose() {
    _locSub?.cancel();
    super.dispose();
  }

  // ===== أصول وصور =====
  Future<BitmapDescriptor> _bitmapFromAsset(String path,
      {int width = 36}) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    final frame = await codec.getNextFrame();
    final bytes =
        (await frame.image.toByteData(format: ui.ImageByteFormat.png))!;
    return BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
  }

  Future<void> _loadMarkerIcon() async {
    try {
      _cityIcon =
          await _bitmapFromAsset('assets/icons/marker_city.png', width: 36);
    } catch (_) {
      _cityIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose);
    }
  }

  // ===== GeoJSON: حدود عُمان =====
  Future<void> _loadOmanOutline() async {
    try {
      final txt =
          await rootBundle.loadString('assets/geo/oman_outline.geojson');
      final data = jsonDecode(txt) as Map<String, dynamic>;
      final feats = (data['features'] as List?) ?? [];

      // امسحي أي سابق
      _polylines.removeWhere((p) => p.polylineId.value == 'oman-outline');

      List<LatLng> outline = [];

      for (final f in feats) {
        final g = (f as Map)['geometry'] as Map<String, dynamic>;
        final type = (g['type'] as String).toLowerCase();
        final coords = g['coordinates'];

        if (type == 'polygon') {
          final ring = (coords as List).first as List;
          for (final e in ring) {
            final lng = (e[0] as num).toDouble();
            final lat = (e[1] as num).toDouble();
            outline.add(LatLng(lat, lng));
          }
        } else if (type == 'multipolygon') {
          for (final poly in (coords as List)) {
            final ring = (poly as List).first as List;
            for (final e in ring) {
              final lng = (e[0] as num).toDouble();
              final lat = (e[1] as num).toDouble();
              outline.add(LatLng(lat, lng));
            }
          }
        }
      }

      if (outline.isNotEmpty) {
        _polylines.add(Polyline(
          polylineId: const PolylineId('oman-outline'),
          points: outline,
          width: 4,
          color: Colors.black54,
          geodesic: true,
        ));
        setState(() {});
      }
    } catch (_) {
      // لو فشل التحميل، نتجاهل بدون رسم مستطيل
    }
  }

  // ===== علامات المدن =====
  void _buildCityMarkers() {
    _markers.removeWhere((m) => m.markerId.value.startsWith('city-'));
    _cityCenters.forEach((key, value) {
      final (center, ar, en) = value;
      _markers.add(Marker(
        markerId: MarkerId('city-$key'),
        position: center,
        icon: _cityIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(title: _isArabic ? ar : en),
        onTap: () => _openCitySheet(key),
      ));
    });
    setState(() {});
  }

  // ===== BottomSheets المدن/الفئات/الصور =====
  Widget _chip(String text, IconData icon, VoidCallback onTap) =>
      ActionChip(avatar: Icon(icon), label: Text(text), onPressed: onTap);

  void _openCitySheet(String cityKey) {
    final label =
        _isArabic ? _cityCenters[cityKey]!.$2 : _cityCenters[cityKey]!.$3;
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _chip(_isArabic ? 'بحر' : 'Sea', Icons.water_outlined,
                      () => _showCityCategoryList(cityKey, 'sea')),
                  _chip(
                      _isArabic ? 'تاريخي' : 'Historic',
                      Icons.museum_outlined,
                      () => _showCityCategoryList(cityKey, 'historic')),
                  _chip(
                      _isArabic ? 'صحاري' : 'Desert',
                      Icons.landscape_outlined,
                      () => _showCityCategoryList(cityKey, 'desert')),
                ],
              ),
              const SizedBox(height: 8),
              Text(_isArabic ? 'اختر الفئة لعرض الصور' : 'Choose a category'),
            ],
          ),
        ),
      ),
    );
  }

  void _showCityCategoryList(String cityKey, String category) {
    final list =
        _gallery[cityKey]?[category] as List<Map<String, dynamic>>? ?? [];
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: list.isEmpty
              ? Center(child: Text(_isArabic ? 'لا توجد عناصر' : 'No items'))
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = list[i];
                    final title = _isArabic
                        ? (item['titleAr'] as String? ?? '')
                        : (item['titleEn'] as String? ?? '');
                    return ListTile(
                      leading: const Icon(Icons.photo_library_outlined),
                      title: Text(title),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => _showGalleryItem(item),
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showGalleryItem(Map<String, dynamic> item) {
    final photos =
        (item['photos'] as List?)?.cast<String>() ?? const <String>[];
    final title = _isArabic
        ? (item['titleAr'] as String? ?? '')
        : (item['titleEn'] as String? ?? '');
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (photos.isEmpty)
                Center(child: Text(_isArabic ? 'لا توجد صور' : 'No photos'))
              else
                GridView.builder(
                  shrinkWrap: true,
                  itemCount: photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(photos[i], fit: BoxFit.cover),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== الموقع والأذونات =====
  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> _initLocation() async {
    if (!await _ensureLocationPermission()) return;
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) _setUserPosition(last);
    try {
      final now = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.best),
      );
      _setUserPosition(now);
    } catch (_) {}
    await _locSub?.cancel();
    _locSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best, distanceFilter: 25),
    ).listen(_setUserPosition, onError: (_) {});
  }

  void _setUserPosition(Position p) {
    _userLatLng = LatLng(p.latitude, p.longitude);
    _markers
      ..removeWhere((m) => m.markerId.value == 'me')
      ..add(Marker(
        markerId: const MarkerId('me'),
        position: _userLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: _isArabic ? 'موقعي' : 'My Location'),
      ));
    setState(() {});
  }

  // ===== واجهة الخريطة =====
  @override
  Widget build(BuildContext context) {
    final t = _t;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isArabic ? 'خريطة عُمان' : 'Oman Map'),
        actions: [
          IconButton(
            tooltip: _isArabic ? 'إظهار كل عُمان' : 'Show Oman',
            onPressed: () => _map
                ?.animateCamera(CameraUpdate.newLatLngBounds(_omanBounds, 28)),
            icon: const Icon(Icons.public),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _isArabic = !_isArabic;
                _buildCityMarkers();
              });
            },
            child: Text(_isArabic ? 'English' : 'العربية'),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'locateMe',
            onPressed: () {
              if (_userLatLng != null) {
                _map?.animateCamera(
                    CameraUpdate.newLatLngZoom(_userLatLng!, 14));
              } else {
                _initLocation();
              }
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'wizard',
            onPressed: _startWizardFlow,
            label: Text(t('start')),
            icon: const Icon(Icons.assistant),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initial,
        cameraTargetBounds: CameraTargetBounds(_omanBounds),
        minMaxZoomPreference: const MinMaxZoomPreference(5.6, 17),
        markers: _markers,
        polylines: _polylines,
        polygons: _polygons,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        onMapCreated: (c) async {
          _map = c;
          _map?.animateCamera(CameraUpdate.newLatLngBounds(_omanBounds, 28));
          _initLocation();
          _buildCityMarkers();
          await _loadOmanOutline(); // ⬅️ حمّلي حدود عُمان من GeoJSON
        },
      ),
    );
  }

  // ===== تدفّق “الأسئلة” (كما هو) =====
  Future<void> _startWizardFlow() async {
    final t = _t;
    final category = await _askCategory();
    if (category == null) return;
    final place = await _askPlace(category);
    if (place == null) return;

    _setSelectedMarker(place.pos, place.name(_isArabic));

    if (_userLatLng != null) {
      final etaMin = await _fetchDriveEtaMinutes(
        origin: _userLatLng!,
        destination: place.pos,
      );
      _drawLine(_userLatLng!, place.pos);
      _snack(_isArabic
          ? 'المدة التقريبية: ${etaMin ?? '-'} دقيقة'
          : 'ETA: ${etaMin ?? '-'} min');
    } else {
      _snack(_isArabic
          ? 'موقعك غير جاهز. اضغط زر تحديد موقعي.'
          : 'Location not ready.');
    }

    final bookHere =
        await _askYesNo(title: t('book_this'), message: place.name(_isArabic));
    final stayCity = await _askStayCity(defaultCity: place.city(_isArabic));
    if (stayCity == null) return;

    Place finalPlace = place;
    if (stayCity != place.city(_isArabic)) {
      final alt = _nearestPlaceInCityOrNearby(stayCity, category);
      if (alt != null && alt.id != place.id) {
        final acceptAlt = await _askYesNo(
          title: t('suggest_alt'),
          message:
              '${t('near_you')} ${alt.name(_isArabic)} • ${t('in_city')} ${alt.city(_isArabic)}',
        );
        if (acceptAlt == true) {
          finalPlace = alt;
          _setSelectedMarker(finalPlace.pos, finalPlace.name(_isArabic));
        }
      }
    }

    final hours = await _askHours();
    if (hours == null) return;

    final from = _userLatLng ?? finalPlace.pos;
    final apiEta =
        await _fetchDriveEtaMinutes(origin: from, destination: finalPlace.pos);
    final fallbackEta = _estimateDriveMinutes(from: from, to: finalPlace.pos);
    final etaMin = apiEta ?? fallbackEta;

    final plan = TripPlan(
      category: category,
      placeName: finalPlace.name(_isArabic),
      placeCity: finalPlace.city(_isArabic),
      stayCity: stayCity,
      willBookHere: (bookHere ?? false),
      hours: hours,
      etaMinutes: etaMin,
      suggestedHotel:
          _isArabic ? 'فندق مقترح بالقرب' : 'Suggested hotel nearby',
      suggestedRestaurant:
          _isArabic ? 'مطعم مقترح قريب' : 'Suggested restaurant nearby',
    );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => TripPlanScreen(plan: plan, isArabic: _isArabic)),
    );
  }

  // ===== حوارات =====
  Future<String?> _askCategory() async {
    final t = _t;
    final items = [
      ('sea', _isArabic ? 'البحر' : 'Sea'),
      ('desert', _isArabic ? 'الصحاري' : 'Desert'),
      ('historic', _isArabic ? 'تاريخي' : 'Historic'),
    ];
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(t('where_go'), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final e in items)
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(e.$2),
                onTap: () => Navigator.pop(context, e.$1),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<Place?> _askPlace(String category) async {
    final list = _places.where((p) => p.category == category).toList()
      ..sort((a, b) => a.name(_isArabic).compareTo(b.name(_isArabic)));
    return showModalBottomSheet<Place>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(_isArabic ? 'اختر المكان' : 'Choose a place',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final p in list)
              ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(p.name(_isArabic)),
                subtitle: Text(p.city(_isArabic)),
                onTap: () => Navigator.pop(context, p),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool?> _askYesNo({required String title, required String message}) {
    final t = _t;
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t('no'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t('yes'))),
        ],
      ),
    );
  }

  Future<String?> _askStayCity({required String defaultCity}) async {
    final cities = _places.map((p) => p.city(_isArabic)).toSet().toList()
      ..sort();
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(_isArabic ? 'وين بتسكن؟' : 'Where will you stay?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final c in cities)
              ListTile(
                leading: Icon(c == defaultCity
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off),
                title: Text(c),
                onTap: () => Navigator.pop(context, c),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<int?> _askHours() async {
    final t = _t;
    int hours = 3;
    return showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('how_many_hours')),
        content: StatefulBuilder(
          builder: (context, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t('hours_value', args: [hours])),
              Slider(
                value: hours.toDouble(),
                min: 1,
                max: 12,
                divisions: 11,
                label: '$hours',
                onChanged: (v) => setS(() => hours = v.round()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(t('cancel'))),
          FilledButton(
              onPressed: () => Navigator.pop(context, hours),
              child: Text(t('confirm'))),
        ],
      ),
    );
  }

  // ===== مساعدات =====
  Place? _nearestPlaceInCityOrNearby(String city, String category) {
    final sameCity = _places
        .where((p) => p.category == category && p.city(_isArabic) == city);
    if (sameCity.isNotEmpty) return sameCity.first;
    final cityCenter = _places
        .firstWhere((p) => p.city(_isArabic) == city, orElse: () => _places[0])
        .pos;
    Place? best;
    double bestKm = double.infinity;
    for (final p in _places.where((p) => p.category == category)) {
      final d = _haversineKm(
        cityCenter.latitude,
        cityCenter.longitude,
        p.pos.latitude,
        p.pos.longitude,
      );
      if (d < bestKm) {
        bestKm = d;
        best = p;
      }
    }
    return best;
  }

  int _estimateDriveMinutes({required LatLng from, required LatLng to}) {
    final km =
        _haversineKm(from.latitude, from.longitude, to.latitude, to.longitude);
    final hours = km / 80.0;
    return (hours * 60).round().clamp(5, 8 * 60);
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double d) => d * pi / 180.0;

  void _setSelectedMarker(LatLng pos, String title) {
    _markers
      ..removeWhere((m) => m.markerId.value == 'selected')
      ..add(Marker(
        markerId: const MarkerId('selected'),
        position: pos,
        infoWindow: InfoWindow(title: title),
      ));
    setState(() {});
    _map?.animateCamera(CameraUpdate.newLatLngZoom(pos, 12));
  }

  void _drawLine(LatLng from, LatLng to) {
    _polylines
      ..removeWhere((p) => p.polylineId.value == 'route')
      ..add(Polyline(
        polylineId: const PolylineId('route'),
        points: [from, to],
        width: 5,
        color: Colors.blueAccent,
        geodesic: true,
      ));
    setState(() {});
  }

  Future<int?> _fetchDriveEtaMinutes({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final key = Secrets.googleMapsKey;
    final url =
        'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric'
        '&origins=${origin.latitude},${origin.longitude}'
        '&destinations=${destination.latitude},${destination.longitude}'
        '&mode=driving&departure_time=now&key=$key';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') return null;
      final rows = data['rows'] as List?;
      if (rows == null || rows.isEmpty) return null;
      final elements = rows.first['elements'] as List?;
      if (elements == null || elements.isEmpty) return null;
      final el = elements.first as Map<String, dynamic>;
      if (el['status'] != 'OK') return null;
      final dur =
          (el['duration_in_traffic'] ?? el['duration']) as Map<String, dynamic>;
      final secs = (dur['value'] as num).toInt();
      return (secs / 60).round();
    } catch (_) {
      return null;
    }
  }

  void _snack(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  String _t(String key, {List<Object>? args}) {
    final ar = {
      'start': 'ابدأ الأسئلة',
      'where_go': 'وين تفضّل تروح؟',
      'book_this': 'تحب أحجز هذا المكان؟',
      'suggest_alt': 'اقتراح قريب',
      'near_you': 'في مكان قريب منك:',
      'in_city': 'في',
      'how_many_hours': ' كم ساعة بتقضي هناك؟',
      'hours_value': 'ساعات: ${args != null ? args.first : ''}',
      'yes': 'نعم',
      'no': 'لا',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
    };
    final en = {
      'start': 'Start questions',
      'where_go': 'What do you prefer?',
      'book_this': 'Do you want to book this place?',
      'suggest_alt': 'Nearby suggestion',
      'near_you': 'A place near you:',
      'in_city': 'in',
      'how_many_hours': 'How many hours will you spend?',
      'hours_value': 'Hours: ${args != null ? args.first : ''}',
      'yes': 'Yes',
      'no': 'Cancel',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
    };
    return _isArabic ? ar[key]! : en[key]!;
  }
}
