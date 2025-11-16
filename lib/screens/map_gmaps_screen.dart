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

/// خطة بسيطة للزيارة (نقدر نخزنها في Firestore لاحقاً)
class TripPlan {
  final Place place;
  final int hours;
  final bool wantHotels;
  final bool wantRestaurants;
  final DateTime createdAt;

  const TripPlan({
    required this.place,
    required this.hours,
    required this.wantHotels,
    required this.wantRestaurants,
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

  // نوع المكان المحدد (بحري / جبلي / ...)
  PlaceType? _selectedType;

  // حدود عُمان (حبس الكاميرا)
  static final LatLngBounds _omanBounds = LatLngBounds(
    southwest: const LatLng(16.8, 51.5),
    northeast: const LatLng(26.5, 60.0),
  );

  double _currentZoom = 7.0;

  bool _welcomeShown = false;

  /// خطط زيارات محفوظة
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
      imageAsset: 'assets/places/suhar/beach_1.jpg',
      position: LatLng(24.3539, 56.7075),
      type: PlaceType.beach,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  String _tr(bool isAr, String ar, String en) => isAr ? ar : en;

  String _placeTypeLabel(PlaceType t, bool isAr) {
    switch (t) {
      case PlaceType.beach:
        return isAr ? 'أماكن بحرية' : 'Beach spots';
      case PlaceType.mountain:
        return isAr ? 'أماكن جبلية' : 'Mountain spots';
      case PlaceType.industrial:
        return isAr ? 'أماكن صناعية' : 'Industrial spots';
      case PlaceType.historic:
        return isAr ? 'أماكن تاريخية' : 'Historic spots';
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
              const SnackBar(content: Text('يجب السماح بالوصول إلى الموقع')),
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
          const SnackBar(content: Text('تعذّر تحديد موقعك حالياً')),
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

    // لما يختار محافظة، نفتح قائمة الأماكن لنفس المحافظة
    _openPlacesSheet(fromGovernorateTap: true);
  }

  /// نص المسافة والوقت (لو توفر الموقع)
  String _distanceText(LatLng target, bool isAr) {
    if (_myLocation == null) {
      return isAr ? 'المسافة غير معروفة' : 'Distance unknown';
    }
    final meters = Geolocator.distanceBetween(
      _myLocation!.latitude,
      _myLocation!.longitude,
      target.latitude,
      target.longitude,
    );
    final km = meters / 1000.0;
    final minutes = km / 80.0 * 60.0;
    return isAr
        ? 'حوالي ${km.toStringAsFixed(1)} كم • ${minutes.toStringAsFixed(0)} دقيقة بالسيارة'
        : 'About ${km.toStringAsFixed(1)} km • ${minutes.toStringAsFixed(0)} min driving';
  }

  /// BottomSheet الترحيبي + اختيار النوع + الوجهة
  Future<void> _openPlacesSheet({bool fromGovernorateTap = false}) async {
    if (!mounted) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    // نحاول تحديد موقعي بهدوء (بدون رسالة خطأ)
    await _ensureMyLocation(quietOnError: true);

    final places = _filteredPlaces();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (context, scrollCtrl) {
            return StatefulBuilder(
              builder: (context, setSheetState) {
                final filtered = _filteredPlaces();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Text(
                        isAr
                            ? 'أهلاً بك في خريطة عُمان السياحية 👋'
                            : 'Welcome to Oman tourist map 👋',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _tr(
                                isAr,
                                _myLocation == null
                                    ? 'يمكنك اختيار وجهة وسنحسب المسافة عند تحديد موقعك.'
                                    : 'تم تحديد موقعك بنجاح، سنحسب المسافة لكل وجهة.',
                                _myLocation == null
                                    ? 'You can pick a destination and we will estimate distance once your location is known.'
                                    : 'Your location is set, we will estimate distance for each destination.',
                              ),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAr
                            ? 'أي نوع من الأماكن تحب تزوره الآن؟'
                            : 'Which type of place would you like to visit?',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final t in PlaceType.values)
                            ChoiceChip(
                              label: Text(
                                _placeTypeLabel(t, isAr),
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
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
                                setSheetState(() {});
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        Expanded(
                          child: Center(
                            child: Text(
                              isAr
                                  ? 'لا توجد أماكن مضافة لهذا النوع في هذه المحافظة حالياً.'
                                  : 'No places of this type in this governorate yet.',
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
                          isAr
                              ? 'اختر الوجهة التي تناسبك:'
                              : 'Choose the destination you prefer:',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollCtrl,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final p = filtered[index];
                              return InkWell(
                                onTap: () async {
                                  Navigator.of(context).pop();
                                  await _goToPlace(p);
                                  _openPlanSheet(p);
                                },
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
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
                                              isAr ? p.nameAr : p.nameEn,
                                              style: const TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isAr ? p.nameEn : p.nameAr,
                                              style: TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _distanceText(p.position, isAr),
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
                        ),
                      ],
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            isAr ? 'إغلاق' : 'Close',
                            style: const TextStyle(fontFamily: 'Tajawal'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// BottomSheet لخطّة الزيارة
  Future<void> _openPlanSheet(Place p) async {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    int selectedHours = 2;
    bool wantHotels = true;
    bool wantRestaurants = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      isAr
                          ? 'خطة زيارتك لـ ${p.nameAr}'
                          : 'Your visit plan to ${p.nameEn}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        isAr
                            ? 'كم ساعة حابة تجلسي هناك؟'
                            : 'How many hours would you like to stay there?',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final h in [2, 4, 6, 8, 12, 24])
                          ChoiceChip(
                            label: Text(
                              isAr ? '$h ساعة' : '$h h',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                color: selectedHours == h
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            selected: selectedHours == h,
                            selectedColor: const Color(0xFF5E2BFF),
                            backgroundColor: Colors.grey.shade200,
                            onSelected: (_) =>
                                setSheetState(() => selectedHours = h),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        isAr
                            ? 'تريد نقترح لك فنادق ومطاعم قريبة؟'
                            : 'Do you want nearby hotels & restaurants?',
                        style: const TextStyle(
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
                      title: Text(
                        isAr ? 'فنادق قريبة' : 'Nearby hotels',
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    CheckboxListTile(
                      value: wantRestaurants,
                      onChanged: (v) =>
                          setSheetState(() => wantRestaurants = v ?? true),
                      title: Text(
                        isAr ? 'مطاعم قريبة' : 'Nearby restaurants',
                        style: const TextStyle(fontFamily: 'Tajawal'),
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
                          final plan = TripPlan(
                            place: p,
                            hours: selectedHours,
                            wantHotels: wantHotels,
                            wantRestaurants: wantRestaurants,
                            createdAt: DateTime.now(),
                          );
                          _savedPlans.add(plan);

                          Navigator.of(context).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isAr
                                    ? 'تم حفظ خطتك لزيارة ${p.nameAr} ✅'
                                    : 'Your plan to visit ${p.nameEn} has been saved ✅',
                                style: const TextStyle(fontFamily: 'Tajawal'),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5E2BFF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isAr ? 'تأكيد الخطة' : 'Confirm plan',
                          style: const TextStyle(
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

  /// الذهاب إلى مكان سياحي + حساب المسافة التقريبية
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
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'المسافة التقريبية: ${km.toStringAsFixed(1)} كم، حوالي ${minutes.toStringAsFixed(0)} دقيقة بالسيارة (تقدير).'
              : 'Approx distance: ${km.toStringAsFixed(1)} km, about ${minutes.toStringAsFixed(0)} min driving (estimate).',
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
      final isAr = Localizations.localeOf(context).languageCode == 'ar';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAr ? 'تعذّر فتح خرائط Google.' : 'Could not open Google Maps.',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      );
    }
  }

  /// عرض اسم المحافظة
  String _govDisplayName(String key, bool isAr) {
    final g = _governorates.firstWhere(
      (g) => g.key == key,
      orElse: () =>
          const GovInfo(key: 'muscat', nameAr: 'مسقط', nameEn: 'Muscat'),
    );

    return isAr ? '${g.nameAr} / ${g.nameEn}' : '${g.nameEn} / ${g.nameAr}';
  }

  void _showWelcomeOnce() {
    if (_welcomeShown) return;
    _welcomeShown = true;
    _openPlacesSheet();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('خريطة عُمان السياحية')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('خريطة عُمان السياحية')),
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
                  _govDisplayName(_selectedGovKey, isAr),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ),
          ),

          // شريط أنواع الأماكن أعلى الخريطة
          Positioned(
            top: 64,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final t in PlaceType.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          _placeTypeLabel(t, isAr),
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: _selectedType == t
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        selected: _selectedType == t,
                        selectedColor: const Color(0xFF5E2BFF),
                        backgroundColor: Colors.white,
                        onSelected: (_) {
                          setState(() {
                            _selectedType =
                                _selectedType == t ? null : t; // إلغاء/اختيار
                          });
                          _openPlacesSheet();
                        },
                      ),
                    ),
                ],
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
                Text(
                  isAr
                      ? 'اضغطي على المحافظة لاكتشافها:'
                      : 'Tap a governorate to explore:',
                  style: const TextStyle(
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
                            isAr
                                ? '${g.nameAr} / ${g.nameEn}'
                                : '${g.nameEn} / ${g.nameAr}',
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
