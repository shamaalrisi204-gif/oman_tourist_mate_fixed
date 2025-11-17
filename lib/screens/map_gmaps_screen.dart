// lib/screens/map_gmaps_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

/// ستايل الخريطة: يخفي أسماء الدول / المدن / الطرق / الخ...
const String _kMapStyle = '''
[
  {
    "featureType": "administrative",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels",
    "stylers": [
      { "visibility": "off" }
    ]
  }
]
''';

/// نوع المكان (بحري / جبلي / صناعي / تاريخي)
enum PlaceType {
  beach, // أماكن بحرية
  mountain, // أماكن جبلية
  industrial, // أماكن صناعية
  historic, // أماكن تاريخية
}

/// =====================
/// موديلات بسيطة
/// =====================

class GovInfo {
  final String key; // مفتاح داخلي
  final String nameAr;
  final String nameEn;

  const GovInfo({
    required this.key,
    required this.nameAr,
    required this.nameEn,
  });
}

class Place {
  final String id;
  final String govKey;
  final String nameAr;
  final String nameEn;
  final String imageAsset;
  final LatLng position;
  final PlaceType type;

  const Place({
    required this.id,
    required this.govKey,
    required this.nameAr,
    required this.nameEn,
    required this.imageAsset,
    required this.position,
    required this.type,
  });
}

/// خطة بسيطة للزيارة (حاليًا محفوظة في الذاكرة – لاحقًا تقدرين تربطيها بـ Firestore أو local DB)
class TripPlan {
  final Place place;

  /// عدد الساعات الفعلي (لو اختار أيام نحوله لساعات داخليًا)
  final double durationHours;

  /// نص جاهز للعرض (مثلاً: "3 ساعات / 3 hours" أو "2 أيام / 2 days")
  final String durationText;

  final bool wantHotels;
  final bool wantRestaurants;
  final bool wantSittings;
  final DateTime createdAt;

  const TripPlan({
    required this.place,
    required this.durationHours,
    required this.durationText,
    required this.wantHotels,
    required this.wantRestaurants,
    required this.wantSittings,
    required this.createdAt,
  });
}

/// نخزّن نقاط كل بوليغون لمحافظة معيّنة
class _GovPolygonData {
  final String govKey;
  final List<LatLng> points;

  _GovPolygonData(this.govKey, this.points);
}

/// =====================
/// الشاشة
/// =====================

class OmanGMapsScreen extends StatefulWidget {
  const OmanGMapsScreen({super.key});

  @override
  State<OmanGMapsScreen> createState() => _OmanGMapsScreenState();
}

class _OmanGMapsScreenState extends State<OmanGMapsScreen> {
  GoogleMapController? _map;

  /// البوليغونات المبنية فعلياً للخريطة
  Set<Polygon> _polygons = {};

  /// بيانات خام للبوليغونات
  final List<_GovPolygonData> _polyData = [];

  /// الماركرز (موقعي + المحافظة المحددة + أماكن سياحية)
  Set<Marker> _markers = {};

  LatLng _center = const LatLng(21.5, 56.0);

  bool _loading = true;
  bool _locating = false;

  // موقعي
  LatLng? _myLocation;

  // مركز كل محافظة
  final Map<String, LatLng> _govCenters = {};

  // مفتاح المحافظة المحددة حالياً
  String _selectedGovKey = 'muscat';

  // نوع المكان المحدد (بحري / جبلي / صناعي / تاريخي)
  PlaceType? _selectedType;

  // حدود عُمان (حبس الكاميرا)
  static final LatLngBounds _omanBounds = LatLngBounds(
    southwest: LatLng(16.8, 51.5),
    northeast: LatLng(26.5, 60.0),
  );

  double _currentZoom = 7.0;

  bool _welcomeShown = false;

  /// وضع الاستخدام:
  /// false = وضع التخطيط (الأسئلة والخطة)
  /// true  = وضع الاستكشاف الحر (ما نفتح شيت الخطة بعد اختيار المكان)
  bool _freeExploreMode = false;

  /// خطط زيارات محفوظة (في الذاكرة فقط)
  final List<TripPlan> _savedPlans = [];

  /// قائمة المحافظات للخيارات اللي تحت
  static const List<GovInfo> _governorates = [
    GovInfo(key: 'muscat', nameAr: 'مسقط', nameEn: 'Muscat'),
    GovInfo(key: 'dhofar', nameAr: 'ظفار', nameEn: 'Dhofar'),
    GovInfo(key: 'musandam', nameAr: 'مسندم', nameEn: 'Musandam'),
    GovInfo(key: 'alburaimi', nameAr: 'البريمي', nameEn: 'Al Buraimi'),
    GovInfo(
      key: 'albatinahnorth',
      nameAr: 'الباطنة الشمالية',
      nameEn: 'Al Batinah North',
    ),
    GovInfo(
      key: 'albatinahsouth',
      nameAr: 'الباطنة الجنوبية',
      nameEn: 'Al Batinah South',
    ),
    GovInfo(
      key: 'addakhliyah',
      nameAr: 'الداخلية',
      nameEn: 'Ad Dakhliyah',
    ),
    GovInfo(
      key: 'ashsharqiyahnorth',
      nameAr: 'الشرقية الشمالية',
      nameEn: 'Ash Sharqiyah North',
    ),
    GovInfo(
      key: 'ashsharqiyahsouth',
      nameAr: 'الشرقية الجنوبية',
      nameEn: 'Ash Sharqiyah South',
    ),
    GovInfo(
      key: 'addhahirah',
      nameAr: 'الظاهرة',
      nameEn: 'Ad Dhahirah',
    ),
    GovInfo(
      key: 'alwusta',
      nameAr: 'الوسطى',
      nameEn: 'Al Wusta',
    ),
  ];

  /// أماكن سياحية (بس أمثلة – عدّلي مكان وصور براحتك)
  final List<Place> _allPlaces = const [
    Place(
      id: 'muttrah-corniche',
      govKey: 'muscat',
      nameAr: 'كورنيش مطرح',
      nameEn: 'Muttrah Corniche',
      imageAsset: 'assets/places/muscat/muttrah_1.jpg',
      position: LatLng(23.6155, 58.5670),
      type: PlaceType.beach,
    ),
    Place(
      id: 'qurum-beach',
      govKey: 'muscat',
      nameAr: 'شاطئ القرم',
      nameEn: 'Qurum Beach',
      imageAsset: 'assets/places/muscat/qurum_1.jpg',
      position: LatLng(23.6139, 58.4744),
      type: PlaceType.beach,
    ),
    Place(
      id: 'salalah-beach',
      govKey: 'dhofar',
      nameAr: 'شاطئ صلالة',
      nameEn: 'Salalah Beach',
      imageAsset: 'assets/places/salalah/beach_1.jpg',
      position: LatLng(17.0150, 54.0924),
      type: PlaceType.beach,
    ),
    // أمثلة لأماكن أخرى:
    Place(
      id: 'nizwa-fort',
      govKey: 'addakhliyah',
      nameAr: 'قلعة نزوى',
      nameEn: 'Nizwa Fort',
      imageAsset: 'assets/places/nizwa/fort_1.jpg',
      position: LatLng(22.9333, 57.5333),
      type: PlaceType.historic,
    ),
    Place(
      id: 'suhar-beach',
      govKey: 'albatinahnorth',
      nameAr: 'شاطئ صحار',
      nameEn: 'Suhar Beach',
      imageAsset: 'assets/places/sohar/beach_1.jpg',
      position: LatLng(24.3539, 56.7075),
      type: PlaceType.beach,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  /// رجع نص عربي/إنجليزي في سطر واحد
  String _bi(String ar, String en) => '$ar / $en';

  String _placeTypeLabel(PlaceType t) {
    switch (t) {
      case PlaceType.beach:
        return 'أماكن بحرية / Beach spots';
      case PlaceType.mountain:
        return 'أماكن جبلية / Mountain spots';
      case PlaceType.industrial:
        return 'أماكن صناعية / Industrial spots';
      case PlaceType.historic:
        return 'أماكن تاريخية / Historic spots';
    }
  }

  /// فلترة الأماكن حسب نوع المكان + المحافظة الحالية
  List<Place> _filteredPlaces() {
    return _allPlaces.where((p) {
      final sameGov = p.govKey == _selectedGovKey;
      final sameType = _selectedType == null ? true : p.type == _selectedType;
      return sameGov && sameType;
    }).toList();
  }

  /// تطبيع اسم المحافظة ليصير key ثابت
  String _norm(String s) {
    return s.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
  }

  /// تحميل ملف المحافظات GeoJSON
  Future<void> _loadGeoJson() async {
    try {
      final geo = await rootBundle
          .loadString('assets/web/geo/oman_governorates.geojson');

      final data = jsonDecode(geo) as Map<String, dynamic>;
      final List features = data['features'] as List;

      for (final fRaw in features) {
        final f = fRaw as Map<String, dynamic>;
        final geom = f['geometry'] as Map<String, dynamic>;
        final type = geom['type'] as String;
        final props = (f['properties'] ?? {}) as Map<String, dynamic>;
        final rawName = (props['NAME_1'] ?? props['NAME'] ?? '') as String;
        final govKey = _norm(rawName);

        final List<LatLng> featurePoints = [];

        void addRing(List coords) {
          final List<LatLng> pts = [];
          for (var c in coords) {
            final lon = (c[0] as num).toDouble();
            final lat = (c[1] as num).toDouble();
            final ll = LatLng(lat, lon);
            pts.add(ll);
            featurePoints.add(ll);
          }
          _polyData.add(_GovPolygonData(govKey, pts));
        }

        if (type == 'Polygon') {
          for (final ring in (geom['coordinates'] as List)) {
            addRing(ring as List);
          }
        } else if (type == 'MultiPolygon') {
          for (final poly in (geom['coordinates'] as List)) {
            for (final ring in (poly as List)) {
              addRing(ring as List);
            }
          }
        }

        if (featurePoints.isNotEmpty) {
          double sumLat = 0;
          double sumLon = 0;

          for (final p in featurePoints) {
            sumLat += p.latitude;
            sumLon += p.longitude;
          }

          _govCenters[govKey] = LatLng(
            sumLat / featurePoints.length,
            sumLon / featurePoints.length,
          );
        }
      }

      _rebuildPolygons();
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('GeoJSON error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  /// إعادة بناء الـ Polygons عشان نغيّر لون المحافظة المحددة
  void _rebuildPolygons() {
    final Set<Polygon> polys = {};

    for (int i = 0; i < _polyData.length; i++) {
      final d = _polyData[i];
      final bool selected = d.govKey == _selectedGovKey;

      polys.add(
        Polygon(
          polygonId: PolygonId('polygon-${d.govKey}-$i'),
          points: d.points,
          strokeWidth: selected ? 3 : 2,
          strokeColor: selected ? const Color(0xFF5E2BFF) : Colors.black,
          fillColor: selected
              ? const Color(0xFF5E2BFF).withOpacity(0.18)
              : Colors.transparent,
          consumeTapEvents: true,
          onTap: () => _onGovernorateSelected(d.govKey),
        ),
      );
    }

    setState(() {
      _polygons = polys;
    });
  }

  /// الحصول على موقعي
  Future<LatLng?> _ensureMyLocation({bool quietOnError = false}) async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();

        if (perm == LocationPermission.denied ||
            perm == LocationPermission.deniedForever) {
          if (!quietOnError && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'يجب السماح بالوصول إلى الموقع / You need to allow location access',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
            );
          }
          return null;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _myLocation = LatLng(pos.latitude, pos.longitude);

      final meMarker = Marker(
        markerId: const MarkerId('me'),
        position: _myLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        zIndex: 10000,
      );

      setState(() {
        _markers = {
          ..._markers.where((m) => m.markerId.value != 'me'),
          meMarker,
        };
      });

      return _myLocation;
    } catch (e) {
      debugPrint('Location error: $e');

      if (!quietOnError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذّر تحديد موقعك حالياً / Could not detect your location now',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        );
      }
      return null;
    }
  }

  Future<void> _goToMyLocation() async {
    if (_map == null) return;

    setState(() => _locating = true);

    final loc = await _ensureMyLocation();

    if (loc != null) {
      _currentZoom = 12;
      await _map!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: loc, zoom: _currentZoom),
        ),
      );
    }

    if (mounted) setState(() => _locating = false);
  }

  /// تكبير / تصغير يدوي بالزر
  Future<void> _zoomIn() async {
    if (_map == null) return;
    _currentZoom = (_currentZoom + 0.5).clamp(6.8, 12.0);
    await _map!.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  Future<void> _zoomOut() async {
    if (_map == null) return;
    _currentZoom = (_currentZoom - 0.5).clamp(6.8, 12.0);
    await _map!.animateCamera(CameraUpdate.zoomTo(_currentZoom));
  }

  /// لما نختار محافظة
  void _onGovernorateSelected(String govKey) {
    _selectedGovKey = govKey;
    _rebuildPolygons();

    final center = _govCenters[govKey];

    if (center != null) {
      final govMarker = Marker(
        markerId: const MarkerId('selected-gov'),
        position: center,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueViolet,
        ),
        zIndex: 9000,
      );

      setState(() {
        _markers = {
          ..._markers.where((m) => m.markerId.value != 'selected-gov'),
          govMarker,
        };
      });

      _currentZoom = 8.5;
      _map?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: _currentZoom),
        ),
      );
    }

    // لما يختار محافظة، نفتح قائمة الأسئلة + الأماكن لنفس المحافظة
    _openPlacesSheet();
  }

  /// نص المسافة والوقت (بالدقائق لو قريب، وبالساعات لو بعيد) – بالعربي والإنجليزي
  String _distanceText(LatLng target) {
    if (_myLocation == null) {
      return 'المسافة غير معروفة / Distance unknown';
    }
    final meters = Geolocator.distanceBetween(
      _myLocation!.latitude,
      _myLocation!.longitude,
      target.latitude,
      target.longitude,
    );
    final km = meters / 1000.0;
    final minutes = km / 80.0 * 60.0; // تقدير بسرعة 80 كم/س

    if (minutes < 60) {
      final mins = minutes.round();
      return 'حوالي $mins دقيقة بالسيارة / About $mins min driving • ${km.toStringAsFixed(1)} كم / km';
    } else {
      final hours = minutes / 60.0;
      final hStr = hours.toStringAsFixed(1);
      return 'حوالي $hStr ساعة بالسيارة / About $hStr hours driving • ${km.toStringAsFixed(1)} كم / km';
    }
  }

  /// شاشة السؤال الأولى: السماح بالموقع (تُستدعى في وضع التخطيط)
  Future<void> _askLocationPermissionSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'تسمح لنا نحدد موقعك بالضبط؟ / Allow us to detect your location precisely?',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'نستخدم موقعك لاقتراح أقرب الأماكن لك ولحساب المسافة والوقت.\nWe use your location to suggest nearby places and estimate distance & time.',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    await _ensureMyLocation();
                    if (mounted) Navigator.of(ctx).pop();
                    // بعد الموقع نفتح نوع المكان + الوجهات
                    _openPlacesSheet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E2BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'نعم، اسمح بتحديد موقعي / Yes, allow my location',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _openPlacesSheet();
                },
                child: const Text(
                  'لاحقاً، أكمل بدون تحديد / Later, continue without location',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// شاشة اختيار نوع المكان + الوجهات (مع معالجة الـ overflow + زر رجوع)
  Future<void> _openPlacesSheet() async {
    if (!mounted) return;

    // نحاول نحدد موقعي بهدوء
    await _ensureMyLocation(quietOnError: true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.95,
          builder: (context, scrollCtrl) {
            final filtered = _filteredPlaces();

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // شريط السحب + زر الرجوع
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 18,
                            ),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          const Spacer(),
                          Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 8, right: 40),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'خريطة عُمان السياحية / Oman Tourist Map',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.place,
                              size: 18, color: Colors.green),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _myLocation == null
                                  ? 'لم يتم تحديد موقعك بعد، يمكنك المتابعة واختيار الوجهة.\nYour location is not set yet, you can still continue and pick a destination.'
                                  : 'تم تحديد موقعك، سنعرض المسافة والوقت لكل وجهة.\nYour location is set, we will show distance and time for each destination.',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'السؤال ١: ما نوع الأماكن التي تحب تزورها الآن؟\nQ1: Which type of places would you like to visit?',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      /// Chips أنواع الأماكن
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // خيار "سياحي عام" = بدون فلتر نوع
                          ChoiceChip(
                            label: const Text(
                              'أماكن سياحية عامة / General tourist places',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                              ),
                            ),
                            selected: _selectedType == null,
                            selectedColor: const Color(0xFF5E2BFF),
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color: _selectedType == null
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedType = null;
                              });
                            },
                          ),
                          for (final t in PlaceType.values)
                            ChoiceChip(
                              label: Text(
                                _placeTypeLabel(t),
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  color: _selectedType == t
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              selected: _selectedType == t,
                              selectedColor: const Color(0xFF5E2BFF),
                              backgroundColor: Colors.grey.shade200,
                              onSelected: (_) {
                                setState(() {
                                  _selectedType = t;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'لا توجد أماكن من هذا النوع في هذه المحافظة حالياً.\nNo places of this type in this governorate yet.',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else ...[
                        Text(
                          'السؤال ٢: اختر المكان الذي يناسبك:\nQ2: Choose the destination you prefer:',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),

                        /// لستة الأماكن – نخليها داخل SingleChildScrollView
                        ListView.builder(
                          itemCount: filtered.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final p = filtered[index];
                            return InkWell(
                              onTap: () async {
                                Navigator.of(context).pop();
                                await _handlePlaceSelection(p);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        p.imageAsset,
                                        width: 70,
                                        height: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${p.nameAr} / ${p.nameEn}',
                                            style: const TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _distanceText(p.position),
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 11,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// التعامل مع اختيار المكان: نقترح الأقرب لو في فرق واضح
  Future<void> _handlePlaceSelection(Place selected) async {
    // نحاول تحديد موقعي (لو مو محدد)
    final myLoc = _myLocation ?? await _ensureMyLocation(quietOnError: true);

    Place finalPlace = selected;

    if (myLoc != null) {
      // مسافة المكان المختار
      final selectedMeters = Geolocator.distanceBetween(
        myLoc.latitude,
        myLoc.longitude,
        selected.position.latitude,
        selected.position.longitude,
      );

      // ندور أقرب مكان من نفس النوع
      Place? nearest;
      double? nearestMeters;

      for (final p in _allPlaces) {
        if (p.type != selected.type) continue;

        final d = Geolocator.distanceBetween(
          myLoc.latitude,
          myLoc.longitude,
          p.position.latitude,
          p.position.longitude,
        );

        if (nearest == null || d < nearestMeters!) {
          nearest = p;
          nearestMeters = d;
        }
      }

      // لو لقينا أقرب بشكل ملحوظ (أقرب بـ 10 كم أو أكثر)
      if (nearest != null &&
          nearest.id != selected.id &&
          nearestMeters != null &&
          selectedMeters - nearestMeters > 10000) {
        await _askCloserSuggestion(
            selected, nearest, selectedMeters, nearestMeters);
        return;
      }
    }

    // لو ما في اقتراح أو مافي فرق كبير، نكمل عادي
    await _goToPlace(finalPlace);
    if (!_freeExploreMode) {
      await _openPlanSheet(finalPlace);
    }
  }

  /// شيت اقتراح مكان أقرب
  Future<void> _askCloserSuggestion(
    Place chosen,
    Place nearest,
    double chosenMeters,
    double nearestMeters,
  ) async {
    final chosenKm = (chosenMeters / 1000.0).toStringAsFixed(1);
    final nearestKm = (nearestMeters / 1000.0).toStringAsFixed(1);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'اخترت ${chosen.nameAr} / ${chosen.nameEn}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'وجدنا لك مكان من نفس النوع أقرب لموقعك:\nWe found a place of the same type that is closer to you:',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      'الأقرب: ${nearest.nameAr} / ${nearest.nameEn}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'يبعد تقريباً $nearestKm كم / about $nearestKm km',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المكان الذي اخترته يبعد تقريباً $chosenKm كم / your chosen place is about $chosenKm km away',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await _goToPlace(nearest);
                    if (!_freeExploreMode) {
                      await _openPlanSheet(nearest);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E2BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'اختر الأقرب لموقعي / Choose the closer place',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _goToPlace(chosen);
                  if (!_freeExploreMode) {
                    await _openPlanSheet(chosen);
                  }
                },
                child: const Text(
                  'أستمر مع المكان الذي اخترته / Continue with my chosen place',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// BottomSheet لخطّة الزيارة (سؤال الساعات/الأيام + فنادق + مطاعم + جلسات)
  Future<void> _openPlanSheet(Place p) async {
    double durationNumber = 2;
    String durationUnit = 'hours'; // 'hours' or 'days'
    bool wantHotels = true;
    bool wantRestaurants = true;
    bool wantSittings = true;

    final durationController = TextEditingController(text: '2');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      'خطة زيارتك لـ ${p.nameAr} / Your visit plan to ${p.nameEn}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'السؤال ٣: كم تنوي تجلس في هذا المكان؟\nQ3: How long do you plan to stay there?',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'أدخل العدد / Enter number (مثلاً 3)',
                              labelStyle: const TextStyle(
                                  fontFamily: 'Tajawal', fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              isDense: true,
                            ),
                            onChanged: (val) {
                              final v = double.tryParse(val);
                              if (v != null && v > 0) {
                                durationNumber = v;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: durationUnit,
                          items: const [
                            DropdownMenuItem(
                              value: 'hours',
                              child: Text(
                                'ساعات / Hours',
                                style: TextStyle(fontFamily: 'Tajawal'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'days',
                              child: Text(
                                'أيام / Days',
                                style: TextStyle(fontFamily: 'Tajawal'),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setSheetState(() {
                              durationUnit = v;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'السؤال ٤: تحب نقترح لك:\nQ4: Would you like us to suggest:',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: wantHotels,
                      onChanged: (v) =>
                          setSheetState(() => wantHotels = v ?? true),
                      title: const Text(
                        'فنادق قريبة / Nearby hotels',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    CheckboxListTile(
                      value: wantRestaurants,
                      onChanged: (v) =>
                          setSheetState(() => wantRestaurants = v ?? true),
                      title: const Text(
                        'مطاعم قريبة / Nearby restaurants',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    CheckboxListTile(
                      value: wantSittings,
                      onChanged: (v) =>
                          setSheetState(() => wantSittings = v ?? true),
                      title: const Text(
                        'أماكن جلسات قريبة / Nearby sitting areas',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          final v = double.tryParse(durationController.text);
                          if (v != null && v > 0) {
                            durationNumber = v;
                          }

                          double durationHours;
                          String durationText;

                          if (durationUnit == 'days') {
                            durationHours = durationNumber * 24.0;
                            durationText =
                                '${durationNumber.toStringAsFixed(1)} يوم / days';
                          } else {
                            durationHours = durationNumber;
                            durationText =
                                '${durationNumber.toStringAsFixed(1)} ساعة / hours';
                          }

                          final plan = TripPlan(
                            place: p,
                            durationHours: durationHours,
                            durationText: durationText,
                            wantHotels: wantHotels,
                            wantRestaurants: wantRestaurants,
                            wantSittings: wantSittings,
                            createdAt: DateTime.now(),
                          );
                          _savedPlans.add(plan);

                          Navigator.of(ctx).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'تم حفظ خطتك لزيارة ${p.nameAr} / Your plan to visit ${p.nameEn} has been saved ✅',
                                style: const TextStyle(fontFamily: 'Tajawal'),
                              ),
                            ),
                          );

                          _showPlanSummary(plan);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E2BFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'تأكيد الخطة / Confirm plan',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// فتح بحث "أماكن قريبة" في خرائط Google (فنادق / مطاعم / جلسات)
  Future<void> _openNearbyInGoogleMaps(Place p, String query) async {
    final q = Uri.encodeComponent(query);
    final url =
        'https://www.google.com/maps/search/$q/@${p.position.latitude},${p.position.longitude},14z';

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذّر فتح خرائط Google / Could not open Google Maps.',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      );
    }
  }

  /// ملخص الخطة + عرض الزمن والمسافة + زر المسار + أزرار المطاعم/الفنادق/الجلسات
  Future<void> _showPlanSummary(TripPlan plan) async {
    final place = plan.place;
    final distanceInfo = _distanceText(place.position);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true, // مهم عشان يسمح بالارتفاع الكامل + السكرول
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            // يخلي الـ BottomSheet يسكّر نفسه بالسكرول وما يطلع overflow
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    'خطة زيارتك / Your plan',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${place.nameAr} / ${place.nameEn}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'المدة: ${plan.durationText}\n'
                          'Duration: ${plan.durationText}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'المسافة والوقت التقريبي: / Approx distance & time:',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          distanceInfo,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'الخيارات التي اخترتها / Your preferences:',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '- فنادق قريبة: ${plan.wantHotels ? 'نعم / Yes' : 'لا / No'}\n'
                          '- مطاعم قريبة: ${plan.wantRestaurants ? 'نعم / Yes' : 'لا / No'}\n'
                          '- أماكن جلسات قريبة: ${plan.wantSittings ? 'نعم / Yes' : 'لا / No'}',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'إذا حاب تعرف مسار الطريق اضغط الزر بالأسفل.\n'
                          'If you want to see the route, tap the button below.',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openInGoogleMaps(place);
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text(
                        'إظهار المسار في خرائط Google / Show route in Google Maps',
                        style: TextStyle(fontFamily: 'Tajawal', fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E2BFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (plan.wantHotels ||
                      plan.wantRestaurants ||
                      plan.wantSittings) ...[
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'أماكن قريبة من الوجهة / Nearby around destination:',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (plan.wantHotels)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openNearbyInGoogleMaps(place, 'hotels'),
                            icon: const Icon(Icons.hotel, size: 18),
                            label: const Text(
                              'فنادق قريبة / Hotels nearby',
                              style: TextStyle(
                                  fontFamily: 'Tajawal', fontSize: 12),
                            ),
                          ),
                        if (plan.wantRestaurants)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openNearbyInGoogleMaps(place, 'restaurants'),
                            icon: const Icon(Icons.restaurant, size: 18),
                            label: const Text(
                              'مطاعم قريبة / Restaurants nearby',
                              style: TextStyle(
                                  fontFamily: 'Tajawal', fontSize: 12),
                            ),
                          ),
                        if (plan.wantSittings)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openNearbyInGoogleMaps(place, 'cafes'),
                            icon: const Icon(Icons.local_cafe, size: 18),
                            label: const Text(
                              'أماكن جلسات / Sitting areas',
                              style: TextStyle(
                                  fontFamily: 'Tajawal', fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'إغلاق / Close',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// الذهاب إلى مكان سياحي + حساب المسافة التقريبية (ماركر + تحريك الكاميرا + رسالة بسيطة)
  Future<void> _goToPlace(Place p) async {
    // ماركر للمكان
    final placeMarker = Marker(
      markerId: MarkerId('place-${p.id}'),
      position: p.position,
      infoWindow: InfoWindow(
        title: p.nameAr,
        snippet: p.nameEn,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueViolet,
      ),
      zIndex: 8000,
    );

    setState(() {
      _markers = {
        ..._markers.where((m) => !m.markerId.value.startsWith('place-')),
        placeMarker,
      };
    });

    _currentZoom = 12;
    _map?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: p.position, zoom: _currentZoom),
      ),
    );

    final myLoc = _myLocation ?? await _ensureMyLocation(quietOnError: true);
    if (myLoc == null || !mounted) return;

    final meters = Geolocator.distanceBetween(
      myLoc.latitude,
      myLoc.longitude,
      p.position.latitude,
      p.position.longitude,
    );

    final km = meters / 1000.0;
    final minutes = km / 80.0 * 60.0;
    final distText = minutes < 60
        ? 'حوالي ${minutes.round()} دقيقة / About ${minutes.round()} min'
        : 'حوالي ${(minutes / 60).toStringAsFixed(1)} ساعة / About ${(minutes / 60).toStringAsFixed(1)} h';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'المسافة التقريبية: $distText (تقدير) • ${km.toStringAsFixed(1)} كم / km (estimate).',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  /// فتح مسار في خرائط Google (حقيقي – طرق حقيقية)
  Future<void> _openInGoogleMaps(Place p) async {
    final loc = _myLocation ?? await _ensureMyLocation(quietOnError: true);

    String originParam = '';
    if (loc != null) {
      originParam = '&origin=${loc.latitude},${loc.longitude}';
    }

    final url = 'https://www.google.com/maps/dir/?api=1'
        '$originParam'
        '&destination=${p.position.latitude},${p.position.longitude}'
        '&travelmode=driving';

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذّر فتح خرائط Google / Could not open Google Maps.',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      );
    }
  }

  /// عرض اسم المحافظة
  String _govDisplayName(String key) {
    final g = _governorates.firstWhere(
      (g) => g.key == key,
      orElse: () => GovInfo(
        key: key,
        // مؤقتاً خليه يعرض الـ key نفسه عشان نعرفه
        nameAr: key,
        nameEn: key,
      ),
    );

    return '${g.nameAr} / ${g.nameEn}';
  }

  /// شاشة اختيار نمط الاستخدام عند أول دخول
  Future<void> _showModeChoiceSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'كيف حاب تستخدم الخريطة؟\nHow would you like to use the map?',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'تقدرين تختارين بين وضع “خطة زيارة” بأسئلة بسيطة تقترح لك أماكن، أو “استكشاف حر” بدون أسئلة.\nYou can choose between a guided visit plan or free exploration.',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _freeExploreMode = false;
                    });
                    Navigator.of(ctx).pop();
                    _askLocationPermissionSheet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E2BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'أبغي أسوي خطة زيارة / I want a visit plan',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _freeExploreMode = true;
                    });
                    Navigator.of(ctx).pop();
                    // استكشاف حر: ما نفتح أسئلة الآن، تستخدمي الخريطة مباشرة
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'أستكشف الخريطة بنفسي / I want to explore freely',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWelcomeOnce() {
    if (_welcomeShown) return;
    _welcomeShown = true;
    _showModeChoiceSheet();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'خريطة عُمان السياحية / Oman Tourist Map',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'خريطة عُمان السياحية / Oman Tourist Map',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 7.0),
            polygons: _polygons,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,

            // حبس الكاميرا داخل حدود عمان
            cameraTargetBounds: CameraTargetBounds(_omanBounds),

            // ما نسمح يبعد كثير عن عمان
            minMaxZoomPreference: const MinMaxZoomPreference(6.5, 12),

            onMapCreated: (c) {
              _map = c;

              // نطبّق الستايل اللي يخفي أسماء الدول / المدن / الطرق
              _map!.setMapStyle(_kMapStyle);

              // نركّز الكاميرا على حدود عمان
              Future.delayed(const Duration(milliseconds: 300), () {
                _map!.animateCamera(
                  CameraUpdate.newLatLngBounds(_omanBounds, 32),
                );
                _showWelcomeOnce();
              });
            },

            onCameraMove: (pos) {
              _currentZoom = pos.zoom;
            },
          ),

          // عنوان المحافظة المحددة
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  _govDisplayName(_selectedGovKey),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ),
          ),

          // شريط المحافظات
          Positioned(
            left: 12,
            right: 12,
            bottom: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اضغط على المحافظة لاكتشافها / Tap a governorate to explore:',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  child: SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _governorates.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final g = _governorates[index];
                        final selected = g.key == _selectedGovKey;

                        return ChoiceChip(
                          label: Text(
                            '${g.nameAr} / ${g.nameEn}',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: selected ? Colors.white : Colors.black87,
                            ),
                          ),
                          selected: selected,
                          selectedColor: const Color(0xFF5E2BFF),
                          backgroundColor: Colors.grey.shade200,
                          onSelected: (_) => _onGovernorateSelected(g.key),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // أزرار التكبير + زر موقعي
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'my_loc',
                  mini: true,
                  onPressed: _locating ? null : _goToMyLocation,
                  child: _locating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
