// lib/screens/map_gmaps_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geolocator/geolocator.dart';

import 'package:url_launcher/url_launcher.dart';

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

  const Place({
    required this.id,
    required this.govKey,
    required this.nameAr,
    required this.nameEn,
    required this.imageAsset,
    required this.position,
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

  /// بيانات خام للبوليغونات (لإعادة البناء لما نغيّر المحافظة المحددة)

  final List<_GovPolygonData> _polyData = [];

  /// الماركرز (موقعي + المحافظة المحددة + أماكن سياحية)

  Set<Marker> _markers = {};

  LatLngBounds? _bounds;

  LatLng _center = const LatLng(21.5, 56.0);

  bool _loading = true;

  bool _locating = false;

  // موقعي

  LatLng? _myLocation;

  // مركز كل محافظة

  final Map<String, LatLng> _govCenters = {};

  // مفتاح المحافظة المحددة حالياً

  String _selectedGovKey = 'muscat';

  // حدود عُمان (حبس الكاميرا)

  static final LatLngBounds _omanBounds = LatLngBounds(
    southwest: LatLng(16.5, 51.5),
    northeast: LatLng(26.5, 60.5),
  );

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

  /// أمثلة أماكن سياحية (عدّلي الإحداثيات والصور براحتك)

  final List<Place> _allPlaces = const [
    Place(
      id: 'muttrah-corniche',
      govKey: 'muscat',
      nameAr: 'كورنيش مطرح',
      nameEn: 'Muttrah Corniche',
      imageAsset: 'assets/places/muscat/muttrah_1.jpg',
      position: LatLng(23.6155, 58.5670),
    ),
    Place(
      id: 'qurum-beach',
      govKey: 'muscat',
      nameAr: 'شاطئ القرم',
      nameEn: 'Qurum Beach',
      imageAsset: 'assets/places/muscat/qurum_1.jpg',
      position: LatLng(23.6139, 58.4744),
    ),
    Place(
      id: 'salalah-beach',
      govKey: 'dhofar',
      nameAr: 'شاطئ صلالة',
      nameEn: 'Salalah Beach',
      imageAsset: 'assets/places/salalah/beach_1.jpg',
      position: LatLng(17.0150, 54.0924),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _loadGeoJson();
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

      double? minLat, maxLat, minLon, maxLon;

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

            minLat = (minLat == null) ? lat : (lat < minLat! ? lat : minLat);

            maxLat = (maxLat == null) ? lat : (lat > maxLat! ? lat : maxLat);

            minLon = (minLon == null) ? lon : (lon < minLon! ? lon : minLon);

            maxLon = (maxLon == null) ? lon : (lon > maxLon! ? lon : maxLon);
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
              sumLat / featurePoints.length, sumLon / featurePoints.length);
        }
      }

      if (minLat != null &&
          maxLat != null &&
          minLon != null &&
          maxLon != null) {
        _bounds = LatLngBounds(
          southwest: LatLng(minLat!, minLon!),
          northeast: LatLng(maxLat!, maxLon!),
        );

        _center = LatLng(
          (minLat! + maxLat!) / 2,
          (minLon! + maxLon!) / 2,
        );
      } else {
        _bounds = _omanBounds;
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
          strokeColor: selected ? const Color(0xFF5E2BFF) : Colors.black87,
          fillColor: selected
              ? const Color(0xFF5E2BFF).withOpacity(0.18)
              : Colors.black.withOpacity(0.03),
          consumeTapEvents: true,
          onTap: () => _onGovernorateSelected(d.govKey),
        ),
      );
    }

    setState(() {
      _polygons = polys;
    });
  }

  /// الحصول على موقعي (تُستخدم للزر ولحساب المسافة)

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

      // ماركر للموقع (ممكن لاحقاً تبدّلينه بأيقونة سهم)

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
      await _map!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: loc, zoom: 12),
        ),
      );
    }

    if (mounted) setState(() => _locating = false);
  }

  /// لما نختار محافظة (من البار أو من التاب على البوليغون)

  void _onGovernorateSelected(String govKey) {
    _selectedGovKey = govKey;

    _rebuildPolygons(); // يغيّر الألوان

    // نحط علامة على مركز المحافظة

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

      _map?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: center, zoom: 8.5),
        ),
      );
    }

    _openPlacesSheet(govKey);
  }

  /// فتح الـ BottomSheet للأماكن السياحية (مع زر رجوع + زر مسار)

  void _openPlacesSheet(String govKey) {
    final places = _allPlaces.where((p) => p.govKey == govKey).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.28,
          minChildSize: 0.18,
          maxChildSize: 0.9,
          builder: (context, controller) {
            final isAr = Localizations.localeOf(context).languageCode == 'ar';

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
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // مقبض السحب

                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 🔙 شريط العنوان + زر رجوع

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'أماكن سياحية في المحافظة'
                                : 'Tourist places in governorate',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  Expanded(
                    child: places.isEmpty
                        ? Center(
                            child: Text(
                              isAr
                                  ? 'لا توجد أماكن مضافة بعد، يمكنك إضافتها لاحقاً.'
                                  : 'No places yet, you can add them later.',
                              style: const TextStyle(fontFamily: 'Tajawal'),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            controller: controller,
                            itemCount: places.length,
                            itemBuilder: (context, index) {
                              final p = places[index];

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: InkWell(
                                    // ضغطة على الكرت: توديه للمكان وتحسب المسافة

                                    onTap: () => _goToPlace(p),

                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Image.asset(
                                            p.imageAsset,
                                            width: 80,
                                            height: 80,
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
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Tajawal',
                                                ),
                                              ),

                                              const SizedBox(height: 4),

                                              Text(
                                                isAr ? p.nameEn : p.nameAr,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                  fontFamily: 'Tajawal',
                                                ),
                                              ),

                                              const SizedBox(height: 6),

                                              // زر المسار في خرائط Google

                                              Align(
                                                alignment: AlignmentDirectional
                                                    .centerStart,
                                                child: TextButton.icon(
                                                  onPressed: () =>
                                                      _openInGoogleMaps(p),
                                                  icon: const Icon(
                                                    Icons.directions,
                                                    size: 18,
                                                  ),
                                                  label: Text(
                                                    isAr
                                                        ? 'إظهار المسار في خرائط Google'
                                                        : 'Show route in Google Maps',
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontFamily: 'Tajawal',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// الذهاب إلى مكان سياحي + حساب المسافة التقريبية

  Future<void> _goToPlace(Place p) async {
    Navigator.of(context).pop(); // نغلق الـ bottom sheet

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

    _map?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: p.position, zoom: 12),
      ),
    );

    // نحاول نحسب المسافة من موقعي (خط مستقيم تقريباً)

    final myLoc = _myLocation ?? await _ensureMyLocation(quietOnError: true);

    if (myLoc == null || !mounted) return;

    final meters = Geolocator.distanceBetween(
      myLoc.latitude,
      myLoc.longitude,
      p.position.latitude,
      p.position.longitude,
    );

    final km = meters / 1000.0;

    // تقدير الوقت على سرعة ٨٠ كم/س

    final minutes = km / 80.0 * 60.0;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAr
              ? 'المسافة التقريبية: ${km.toStringAsFixed(1)} كم، حوالي ${minutes.toStringAsFixed(0)} دقيقة بالسيارة (تقدير).'
              : 'Approx distance: ${km.toStringAsFixed(1)} km, about ${minutes.toStringAsFixed(0)} min driving (estimate).',
        ),
      ),
    );
  }

  /// فتح مسار في خرائط Google من موقعي إلى المكان السياحي

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
          ),
        ),
      );
    }
  }

  /// عرض اسم المحافظة الحالي في الأعلى

  String _govDisplayName(String key, bool isAr) {
    final g = _governorates.firstWhere(
      (g) => g.key == key,
      orElse: () =>
          const GovInfo(key: 'muscat', nameAr: 'مسقط', nameEn: 'Muscat'),
    );

    return isAr ? '${g.nameAr} / ${g.nameEn}' : '${g.nameEn} / ${g.nameAr}';
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    if (_loading || _bounds == null) {
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
            initialCameraPosition: CameraPosition(target: _center, zoom: 6.8),
            polygons: _polygons,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            cameraTargetBounds: CameraTargetBounds(_omanBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(5.8, 12),
            onMapCreated: (c) {
              _map = c;

              if (_bounds != null) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  _map!.animateCamera(
                    CameraUpdate.newLatLngBounds(_bounds!, 32),
                  );
                });
              }
            },
          ),

          // عنوان المحافظة المحددة في الأعلى

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

          // شريط المحافظات أسفل الخريطة

          Positioned(
            left: 12,
            right: 12,
            bottom: 80,
            child: Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
          ),

          // زر موقعي

          Positioned(
            left: 24,
            right: 24,
            bottom: 20,
            child: ElevatedButton.icon(
              onPressed: _locating ? null : _goToMyLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 4,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                isAr ? 'موقعي / My location' : 'My location / موقعي',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
