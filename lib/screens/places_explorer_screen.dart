// lib/screens/places_explorer_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

import 'package:url_launcher/url_launcher.dart';

/// حطي هنا مفتاح Google (Maps + Places)

/// للتجارب فقط، في الإنتاج يفضل تحطينه في backend أو Cloud Functions.

const String kGoogleApiKey = 'YOUR_GOOGLE_API_KEY_HERE';

/// ستايل خريطة بسيط (إخفاء أسماء الدول والطرق)

const String kMapStyle = '''

[

  {

    "featureType": "administrative",

    "elementType": "labels",

    "stylers": [{ "visibility": "off" }]

  },

  {

    "featureType": "poi",

    "elementType": "labels",

    "stylers": [{ "visibility": "off" }]

  },

  {

    "featureType": "road",

    "elementType": "labels",

    "stylers": [{ "visibility": "off" }]

  },

  {

    "featureType": "transit",

    "elementType": "labels",

    "stylers": [{ "visibility": "off" }]

  },

  {

    "featureType": "water",

    "elementType": "labels",

    "stylers": [{ "visibility": "off" }]

  }

]

''';

/// أنواع الأماكن (لربطها مع Google Places type)

enum PlacesCategory {
  hotels,

  restaurants,

  cafes,

  attractions,
}

extension PlacesCategoryExt on PlacesCategory {
  String get googleType {
    switch (this) {
      case PlacesCategory.hotels:
        return 'lodging';

      case PlacesCategory.restaurants:
        return 'restaurant';

      case PlacesCategory.cafes:
        return 'cafe';

      case PlacesCategory.attractions:
        return 'tourist_attraction';
    }
  }

  String get label {
    switch (this) {
      case PlacesCategory.hotels:
        return 'أماكن الإقامة';

      case PlacesCategory.restaurants:
        return 'مطاعم';

      case PlacesCategory.cafes:
        return 'كافيهات';

      case PlacesCategory.attractions:
        return 'أماكن سياحية';
    }
  }

  IconData get icon {
    switch (this) {
      case PlacesCategory.hotels:
        return Icons.hotel;

      case PlacesCategory.restaurants:
        return Icons.restaurant;

      case PlacesCategory.cafes:
        return Icons.local_cafe;

      case PlacesCategory.attractions:
        return Icons.attractions;
    }
  }
}

/// موديل للنتائج الجاية من Google Places

class NearbyPlace {
  final String placeId;

  final String name;

  final double lat;

  final double lng;

  final String? vicinity;

  final double? rating;

  final String? photoReference;

  NearbyPlace({
    required this.placeId,
    required this.name,
    required this.lat,
    required this.lng,
    this.vicinity,
    this.rating,
    this.photoReference,
  });

  LatLng get position => LatLng(lat, lng);
}

class PlacesExplorerScreen extends StatefulWidget {
  const PlacesExplorerScreen({super.key});

  @override
  State<PlacesExplorerScreen> createState() => _PlacesExplorerScreenState();
}

class _PlacesExplorerScreenState extends State<PlacesExplorerScreen> {
  GoogleMapController? _mapController;

  LatLng _initialCenter = const LatLng(21.5, 56.0); // وسط عمان

  LatLng? _myLocation;

  bool _loadingLocation = false;

  bool _loadingPlaces = false;

  PlacesCategory _selectedCategory = PlacesCategory.restaurants;

  List<NearbyPlace> _nearbyPlaces = [];

  Set<Marker> _markers = {};

  bool _welcomeShown = false;

  /// حدود عمان (عشان الكاميرا ما تطلع بعيد)

  static final LatLngBounds _omanBounds = LatLngBounds(
    southwest: const LatLng(16.8, 51.5),
    northeast: const LatLng(26.5, 60.0),
  );

  @override
  void initState() {
    super.initState();

    // نحمّل موقعي أول ما تفتح الشاشة بهدوء

    _ensureMyLocation(quietOnError: true);
  }

  // ------------ تشغيل Google Places -------------

  Future<void> _loadNearbyPlaces(PlacesCategory category) async {
    final loc = await _ensureMyLocation();

    if (loc == null) return;

    setState(() {
      _selectedCategory = category;

      _loadingPlaces = true;
    });

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=${loc.latitude},${loc.longitude}'
      '&radius=7000' // 7 كم تقريبًا – عدلي الرقم إذا حابة

      '&type=${category.googleType}'
      '&language=ar'
      '&key=$kGoogleApiKey',
    );

    try {
      final resp = await http.get(url);

      if (resp.statusCode != 200) {
        _showSnack(
          'تعذّر الاتصال بـ Google Places (code: ${resp.statusCode})',
        );

        setState(() => _loadingPlaces = false);

        return;
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;

      final results = (data['results'] as List?) ?? [];

      final List<NearbyPlace> places = [];

      final Set<Marker> markers = {};

      // ماركر موقعي إن وجد

      if (_myLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('me'),
            position: _myLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            zIndex: 1000,
            infoWindow: const InfoWindow(
              title: 'موقعي',
            ),
          ),
        );
      }

      for (final r in results.take(20)) {
        final m = r as Map<String, dynamic>;

        final placeId = (m['place_id'] ?? '') as String;

        if (placeId.isEmpty) continue;

        final name = (m['name'] ?? '') as String;

        final vicinity = (m['vicinity'] ?? '') as String?;

        final rating = (m['rating'] as num?)?.toDouble();

        final geom = (m['geometry'] ?? {}) as Map<String, dynamic>;

        final locJson = (geom['location'] ?? {}) as Map<String, dynamic>;

        final lat = (locJson['lat'] as num?)?.toDouble();

        final lng = (locJson['lng'] as num?)?.toDouble();

        if (lat == null || lng == null) continue;

        String? photoRef;

        final photos = m['photos'] as List?;

        if (photos != null && photos.isNotEmpty) {
          final first = photos.first as Map<String, dynamic>;

          photoRef = first['photo_reference'] as String?;
        }

        final p = NearbyPlace(
          placeId: placeId,
          name: name,
          lat: lat,
          lng: lng,
          vicinity: vicinity,
          rating: rating,
          photoReference: photoRef,
        );

        places.add(p);

        markers.add(
          Marker(
            markerId: MarkerId('place-$placeId'),
            position: p.position,
            infoWindow: InfoWindow(
              title: name,
              snippet: vicinity,
            ),
          ),
        );
      }

      setState(() {
        _nearbyPlaces = places;

        _markers = markers;

        _loadingPlaces = false;
      });

      // نقرّب الكاميرا على موقعي

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: loc, zoom: 13),
        ),
      );
    } catch (e) {
      _showSnack('حدث خطأ أثناء جلب البيانات من Google Places');

      setState(() => _loadingPlaces = false);
    }
  }

  String? _buildPhotoUrl(String? photoRef) {
    if (photoRef == null) return null;

    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400'
        '&photo_reference=$photoRef'
        '&key=$kGoogleApiKey';
  }

  // ------------ الموقع -------------

  Future<LatLng?> _ensureMyLocation({bool quietOnError = false}) async {
    try {
      if (_myLocation != null) return _myLocation;

      setState(() => _loadingLocation = true);

      LocationPermission perm = await Geolocator.checkPermission();

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!quietOnError && mounted) {
          _showSnack(
            'يجب السماح بالوصول إلى الموقع لاستخدام هذه الميزة.',
          );
        }

        setState(() => _loadingLocation = false);

        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _myLocation = LatLng(pos.latitude, pos.longitude);

      setState(() {
        _loadingLocation = false;

        _markers = {
          ..._markers.where((m) => m.markerId.value != 'me'),
          Marker(
            markerId: const MarkerId('me'),
            position: _myLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            zIndex: 1000,
          ),
        };
      });

      return _myLocation;
    } catch (e) {
      if (!quietOnError && mounted) {
        _showSnack('تعذّر تحديد موقعك حالياً.');
      }

      setState(() => _loadingLocation = false);

      return null;
    }
  }

  Future<void> _goToMyLocation() async {
    final loc = await _ensureMyLocation();

    if (loc == null || _mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: loc, zoom: 13),
      ),
    );
  }

  // ------------ UI Helpers -------------

  void _showSnack(String msg) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  void _showWelcomeOnce() {
    if (_welcomeShown) return;

    _welcomeShown = true;

    // يسأل المستخدم: خطة ولا استكشاف؟

    showModalBottomSheet(
      context: context,
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
                'كيف تحب تبدأ رحلتك؟',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'تقدرين تطلعين خطة سريعة أو تستكشفين الخريطة بنفسك.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();

                    // حالياً بس نحمّل أقرب مطاعم كـ بداية للخطة

                    _loadNearbyPlaces(PlacesCategory.restaurants);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E2BFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'سوي لي خطة سريعة (مطاعم قريبة)',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();

                  // استكشاف بدون شيء
                },
                child: const Text(
                  'أستكشف بنفسي',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openRouteTo(NearbyPlace place) async {
    LatLng? origin = _myLocation ?? await _ensureMyLocation(quietOnError: true);

    String originParam = '';

    if (origin != null) {
      originParam = '&origin=${origin.latitude},${origin.longitude}';
    }

    final url = 'https://www.google.com/maps/dir/?api=1'
        '$originParam'
        '&destination=${place.lat},${place.lng}'
        '&travelmode=driving';

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('تعذّر فتح خرائط Google.');
    }
  }

  // ------------ Build -------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'خريطة عُمان السياحية',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: _initialCenter, zoom: 7),
            cameraTargetBounds: CameraTargetBounds(_omanBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(6.5, 18),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;

              _mapController!.setMapStyle(kMapStyle);

              Future.delayed(const Duration(milliseconds: 400), () {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngBounds(_omanBounds, 32),
                );

                _showWelcomeOnce();
              });
            },
          ),

          // شريط الفئات (مطاعم/فنادق/كافيهات/أماكن سياحية)

          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemBuilder: (ctx, i) {
                  final cat = PlacesCategory.values[i];

                  final selected = cat == _selectedCategory;

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          cat.icon,
                          size: 18,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    selected: selected,
                    selectedColor: const Color(0xFF5E2BFF),
                    backgroundColor: Colors.white.withOpacity(0.92),
                    onSelected: (_) => _loadNearbyPlaces(cat),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: PlacesCategory.values.length,
              ),
            ),
          ),

          // مسار الكروت بالصور (من Google Photos API أو placeholder)

          Positioned(
            left: 0,
            right: 0,
            bottom: 100,
            child: SizedBox(
              height: 150,
              child: _loadingPlaces
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _nearbyPlaces.isEmpty
                      ? const Center(
                          child: Text(
                            'اختر فئة من الأعلى لعرض الأماكن القريبة.',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          scrollDirection: Axis.horizontal,
                          itemCount: _nearbyPlaces.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (ctx, index) {
                            final p = _nearbyPlaces[index];

                            final photoUrl = _buildPhotoUrl(p.photoReference);

                            return GestureDetector(
                              onTap: () {
                                _mapController?.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(
                                      target: p.position,
                                      zoom: 16,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: 230,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.14),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(18),
                                        topRight: Radius.circular(18),
                                      ),
                                      child: SizedBox(
                                        height: 90,
                                        width: double.infinity,
                                        child: photoUrl != null
                                            ? Image.network(
                                                photoUrl,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.asset(
                                                'assets/places/generic/placeholder.jpg',
                                                fit: BoxFit.cover,
                                              ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (p.vicinity != null &&
                                              p.vicinity!.isNotEmpty)
                                            Text(
                                              p.vicinity!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Tajawal',
                                                fontSize: 11,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (p.rating != null)
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      size: 14,
                                                      color: Colors.amber,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      p.rating!
                                                          .toStringAsFixed(1),
                                                      style: const TextStyle(
                                                        fontFamily: 'Tajawal',
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              TextButton(
                                                onPressed: () =>
                                                    _openRouteTo(p),
                                                child: const Text(
                                                  'المسار',
                                                  style: TextStyle(
                                                    fontFamily: 'Tajawal',
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),

          // زر موقعي + تكبير/تصغير بسيط

          Positioned(
            right: 16,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'my_loc_btn',
                  mini: true,
                  onPressed: _loadingLocation ? null : _goToMyLocation,
                  child: _loadingLocation
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
