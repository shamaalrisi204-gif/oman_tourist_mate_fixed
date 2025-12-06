// lib/screens/map_gmaps_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:geolocator/geolocator.dart';

import 'package:url_launcher/url_launcher.dart';

import '../models/gov_places.dart';

import 'governorate_places_screen.dart';

import 'package:geocoding/geocoding.dart' as geocoding;

import 'your_trip_screen.dart';
import '../models/trip_plan.dart'
    show MapTripPlan, kTripPlans, kTripName, kTripDays, kTripStartDate;

import 'flight_services_screen.dart';
import '../models/place_data.dart' show PlaceType;
import '../widgets/create_trip_sheet.dart';

String? kTripName;

int kTripDays = 1;

DateTime? kTripStartDate;
Future<void> showCreateTripSheet(BuildContext context) async {
  final nameController = TextEditingController();

  int days = 3;

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
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'إنشاء رحلة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الرحلة',
                    labelStyle: TextStyle(fontFamily: 'Tajawal'),
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'عدد الأيام',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (days > 1) {
                          setSheetState(() => days--);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$days',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setSheetState(() => days++);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kDarkBeige,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      kTripName = nameController.text.trim().isEmpty
                          ? 'رحلتي'
                          : nameController.text.trim();

                      kTripDays = days;

                      Navigator.of(ctx).pop();
                    },
                    child: const Text(
                      'إنشاء رحلة',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

const Color kBeige = Color(0xFFF6EFE4); // خلفيات

const Color kDarkBeige = Color(0xFFB68A53); // أزرار / عناصر مميزة

/// نوع المكان (بحري / جبلي / صناعي / تاريخي)

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

  final PlaceType type; // 👈 هذا الآن من place_data.dart

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

/// مكان واحد للبحث (اسم عربي/إنجليزي + إحداثيات)

class SearchPlace {
  final String nameAr;

  final String nameEn;

  final double lat;

  final double lon;

  SearchPlace({
    required this.nameAr,
    required this.nameEn,
    required this.lat,
    required this.lon,
  });
}

/// خطة بسيطة للزيارة (للتخطيط)

class MapTripPlan {
  final Place place;

  final double durationHours;

  final String durationText;

  final bool wantHotels;

  final bool wantRestaurants;

  final bool wantSittings;

  final DateTime createdAt;

  /// اليوم داخل الرحلة (1 = اليوم الأول)

  final int day;

  const MapTripPlan({
    required this.place,
    required this.durationHours,
    required this.durationText,
    required this.wantHotels,
    required this.wantRestaurants,
    required this.wantSittings,
    required this.createdAt,
    required this.day,
  });
}

/// نخزّن نقاط كل بوليغون لمحافظة معيّنة

class _GovPolygonData {
  final String govKey;

  final List<LatLng> points;

  _GovPolygonData(this.govKey, this.points);
}

class OmanGMapsScreen extends StatefulWidget {
  final bool enablePlanning;

  final bool guestMode;
  final bool isArabic;

  const OmanGMapsScreen({
    super.key,
    this.enablePlanning = true,
    this.guestMode = false,
    required this.isArabic,
  });

  @override
  State<OmanGMapsScreen> createState() => _OmanGMapsScreenState();
}

// قائمة الخطط المشتركة لكل التطبيق

final List<MapTripPlan> kTripPlans = [];

class _OmanGMapsScreenState extends State<OmanGMapsScreen> {
  final List<MapTripPlan> _savedPlans = [];

  bool _showQuickQuestions = true;

  GoogleMapController? _map;

  final TextEditingController _searchController = TextEditingController();

  List<SearchPlace> _allSearchPlaces = []; // كل المناطق من ملف HOTOSM

  List<SearchPlace> _suggestions = []; // الاقتراحات اللي تحت مربّع البحث

  Set<Polygon> _polygons = {};

  final List<_GovPolygonData> _polyData = [];

  Set<Marker> _markers = {};

  LatLng _center = const LatLng(21.5, 56.0);

  bool _loading = true;

  bool _locating = false;

  // موقعي

  LatLng? _myLocation;

  static final LatLngBounds _omanBounds = LatLngBounds(
    southwest: LatLng(16.40, 52.00),
    northeast: LatLng(26.55, 60.30),
  );
// موقع مطار مسقط الدولي

  static const LatLng _muscatAirport = LatLng(23.6008679, 58.2828023);

  BitmapDescriptor? _flightIcon;

  Future<void> _loadFlightIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(32, 32)), // 👈 صغير

      'assets/icons/plane_pin.png', // تأكدي من المسار
    );

    setState(() => _flightIcon = icon);

    _addMuscatFlightMarker();
  }

  void _addMuscatFlightMarker() {
    final marker = Marker(
      markerId: const MarkerId('muscat_airport'),
      position: _muscatAirport,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      infoWindow: InfoWindow(
        title: widget.isArabic
            ? 'مطار مسقط الدولي'
            : 'Muscat International Airport',
        snippet: widget.isArabic
            ? 'اضغطي لعرض رحلات الطيران'
            : 'Tap to view flight services',
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlightServicesScreen(
              isArabic: widget.isArabic,
              isGuest: widget.guestMode,
            ),
          ),
        );
      },
    );

    setState(() => _markers.add(marker));
  }

  // 🔐 لو الأسئلة ظاهرة والتخطيط مفعّل → نعتبر الخريطة "مقفولة"

  bool get _mapLocked => _planningEnabled && _showQuickQuestions;

  void _showLockedSnack() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: kDarkBeige,
        content: Text(
          'جاوبي على الأسئلة أولًا أو اضغطي "تخطي" علشان تستخدمي الخريطة 😊',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  // مركز كل محافظة

  final Map<String, LatLng> _govCenters = {};

  // مفتاح المحافظة المحددة حالياً

  String _selectedGovKey = 'muscat';

  // نوع المكان المحدد (بحري / جبلي / صناعي / تاريخي)

  PlaceType? _selectedType;

  void _goToTripPlannerAfterTypeSelected(PlaceType? type) {
    // نسكّر البوتوم شيت

    Navigator.pop(context);

    // نحول الـ enum لنص بسيط

    String category;

    if (type == null) {
      category = 'general';
    } else if (type == PlaceType.beach) {
      category = 'beach';
    } else if (type == PlaceType.mountain) {
      category = 'mountain';
    } else if (type == PlaceType.industrial) {
      category = 'industrial';
    } else if (type == PlaceType.historic) {
      category = 'historic';
    } else {
      category = 'general';
    }

    // افتح شاشة الـ Trip Planner (أو AiChat لو تبين)

    Navigator.pushNamed(
      context,

      '/trip_planner', // غيّريها لـ '/ai_chat' لو تبين الشات

      arguments: {
        'category': category,
        'governorate': _selectedGovKey,
      },
    );
  }

  /// فلترة الأماكن حسب المحافظة المختارة + نوع المكان (لو موجود)

  List<Place> _filteredPlaces() {
    return _allPlaces.where((p) {
      if (p.govKey != _selectedGovKey) return false;

      if (_selectedType != null && p.type != _selectedType) return false;

      return true;
    }).toList();
  }

  double _currentZoom = 7.0;

  bool _welcomeShown = false;

  /// وضع الاستخدام:

  /// false = وضع التخطيط (الأسئلة والخطة)

  /// true  = وضع الاستكشاف الحر

  bool _freeExploreMode = false;

  /// هذا يقرأ قيمة البارامتر من الـ Widget

  bool get _planningEnabled => widget.enablePlanning;

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

  // ✅ كل الأماكن اللي نستخدمها في الأسئلة (بحري / جبلي / صناعي / تاريخي)

  final List<Place> _allPlaces = const [
    Place(
      id: 'muttrah_corniche_sea',
      govKey: 'muscat',
      nameAr: 'كورنيش مطرح (بحري)',
      nameEn: 'Muttrah Corniche (Sea)',
      imageAsset: 'assets/places/muscat/muttrah_3.jpg',
      position: LatLng(23.6155, 58.5670),
      type: PlaceType.beach,
    ),
    Place(
      id: 'qurum_beach_1',
      govKey: 'muscat',
      nameAr: 'شاطئ القرم ١',
      nameEn: 'Qurum Beach 1',
      imageAsset: 'assets/places/muscat/qurum_1.jpg',
      position: LatLng(23.624667, 58.475167),
      type: PlaceType.beach,
    ),
    Place(
      id: 'qurum_beach_2',
      govKey: 'muscat',
      nameAr: 'شاطئ القرم ٢',
      nameEn: 'Qurum Beach 2',
      imageAsset: 'assets/places/muscat/qurum_2.jpg',
      position: LatLng(23.6145, 58.4760),
      type: PlaceType.beach,
    ),
    Place(
      id: 'muttrah_old_souk',
      govKey: 'muscat',
      nameAr: 'سوق مطرح القديم',
      nameEn: 'Muttrah Old Souq',
      imageAsset: 'assets/places/muscat/muttrah_1.jpg',
      position: LatLng(23.6165, 58.5660),
      type: PlaceType.historic,
    ),
    Place(
      id: 'muttrah_gate',
      govKey: 'muscat',
      nameAr: 'بوابة مطرح',
      nameEn: 'Muttrah Gate',
      imageAsset: 'assets/places/muscat/muttrah_2.jpg',
      position: LatLng(23.6160, 58.5650),
      type: PlaceType.historic,
    ),
    Place(
      id: 'qasr_alalam_place',
      govKey: 'muscat',
      nameAr: 'قصر العلم',
      nameEn: 'Qasr Al Alam',
      imageAsset: 'assets/places/muscat/qasr_alalm.jpg',
      position: LatLng(23.6160124, 58.5945746),
      type: PlaceType.historic,
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

  // 🌟 الأماكن المختارة ضمن "رحلتي"

  final Set<String> _tripPlaceIds = {};

  bool _isInTrip(Place p) => _tripPlaceIds.contains(p.id);

// الأماكن نفسها كـ Place (نستخدمها لو احتجنا)

  List<Place> get _tripPlaces =>
      _allPlaces.where((p) => _tripPlaceIds.contains(p.id)).toList();

// إضافة مكان إلى الرحلة كخطة MapTripPlan

  void _addPlaceToTrip(Place p) {
    // لو المكان مضاف من قبل لا نكرر

    if (_tripPlaceIds.contains(p.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'هذا المكان مضاف مسبقًا إلى رحلتك ✅',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      return;
    }

    final plan = MapTripPlan(
      place: p,

      durationHours: 2, // تقدير مبدئي

      durationText: 'حوالي ساعتين مقترحة',

      wantHotels: true,

      wantRestaurants: true,

      wantSittings: false,

      createdAt: DateTime.now(),

      day: 1, // 👈 حالياً نحطه في اليوم الأول
    );

    setState(() {
      _tripPlaceIds.add(p.id); // نعلّم إنه مضاف

      kTripPlans.add(plan); // نخزن الخطة في الليست المشتركة
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تمت إضافة المكان إلى رحلتك ✅',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _addPlaceToTripWithSheet(Place place) async {
    if (kTripDays <= 0 || kTripName == null) {
      await showCreateTripSheet(context);
      if (kTripDays <= 0 || kTripName == null) return;
    }

    int selectedDay = 1;
    int durationHours = 2;

    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _buildAddPlaceSheet(ctx, place, selectedDay, durationHours);
      },
    );

    if (result == null) return;

    final day = result['day'] ?? 1;
    final hours = result['durationHours'] ?? 2;

    setState(() {
      _tripPlaceIds.add(place.id);
      kTripPlans.add(
        MapTripPlan(
          place: place,
          day: day,
          durationText: '$hours ساعة تقريباً',
          durationHours: hours.toDouble(),
          wantHotels: true,
          wantRestaurants: true,
          wantSittings: false,
          createdAt: DateTime.now(),
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تمت إضافة المكان إلى رحلتك ✅',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YourTripScreen(plans: kTripPlans),
      ),
    );
  }

  Widget _buildAddPlaceSheet(
    BuildContext ctx,
    Place place,
    int selectedDay,
    int durationHours,
  ) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Text(
                'إضافة هذا المكان إلى رحلتك',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                place.nameAr,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 20),

              // اختيار اليوم
              const Text(
                'في أي يوم من الرحلة تبي تزور هذا المكان؟',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (selectedDay > 1) {
                        setSheetState(() => selectedDay--);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    'اليوم $selectedDay من $kTripDays',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (selectedDay < kTripDays) {
                        setSheetState(() => selectedDay++);
                      }
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // مدة الزيارة
              const Text(
                'مدة الزيارة (بالساعات تقريباً)',
                style: TextStyle(fontFamily: 'Tajawal', fontSize: 14),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (durationHours > 1) {
                        setSheetState(() => durationHours--);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$durationHours ساعة',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setSheetState(() => durationHours++);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop({
                      'day': selectedDay,
                      'durationHours': durationHours,
                    });
                  },
                  child: const Text(
                    'إضافة للمخطط',
                    style: TextStyle(fontFamily: 'Tajawal'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadPlacesDb() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/web/geo/hotosm_omn_populated_places_points_geojson.geojson',
      );

      final data = jsonDecode(raw) as Map<String, dynamic>;

      final features = data['features'] as List;

      final List<SearchPlace> loaded = [];

      for (final f in features) {
        final feature = f as Map<String, dynamic>;

        final props = feature['properties'] as Map<String, dynamic>;

        final geom = feature['geometry'] as Map<String, dynamic>;

        if (geom['type'] != 'Point') continue;

        final coords = geom['coordinates'] as List;

        final double lon = (coords[0] as num).toDouble();

        final double lat = (coords[1] as num).toDouble();

        final String nameAr = (props['name:ar'] ??
                    props['name_ar'] ??
                    props['NAME_AR'] ??
                    props['name'])
                ?.toString() ??
            '';

        final String nameEn = (props['name:en'] ??
                    props['name_en'] ??
                    props['NAME_EN'] ??
                    props['name'])
                ?.toString() ??
            '';

        if (nameAr.isEmpty && nameEn.isEmpty) continue;

        loaded.add(
          SearchPlace(
            nameAr: nameAr,
            nameEn: nameEn,
            lat: lat,
            lon: lon,
          ),
        );
      }

      setState(() {
        _allSearchPlaces = loaded;
      });

      debugPrint('✅ Loaded ${loaded.length} HOTOSM places for search');
    } catch (e) {
      debugPrint('❌ Error loading HOTOSM places DB: $e');
    }
  }

  void _onSearchChanged(String value) {
    final q = value.trim().toLowerCase();

    // لو أقل من حرفين لا نعرض اقتراحات

    if (q.length < 2) {
      setState(() {
        _suggestions = [];
      });

      return;
    }

    final List<SearchPlace> matches = _allSearchPlaces
        .where((p) {
          final en = p.nameEn.toLowerCase();

          final ar = p.nameAr;

          return en.contains(q) || ar.contains(value);
        })
        .take(12)
        .toList(); // نكتفي بـ 12 اقتراح

    setState(() {
      _suggestions = matches;
    });
  }
  // ⭐ دالة الذهاب للمكان المختار من البحث الذكي

  Future<void> _goToSearchPlace(SearchPlace place) async {
    if (_mapLocked) {
      _showLockedSnack();

      return;
    }

    final target = LatLng(place.lat, place.lon);

    // نضيف ماركر لهذا المكان

    final marker = Marker(
      markerId: const MarkerId('search-result'),
      position: target,
      infoWindow: InfoWindow(
        title: place.nameEn.isNotEmpty ? place.nameEn : place.nameAr,
        snippet: place.nameAr.isNotEmpty ? place.nameAr : null,
      ),
      zIndex: 9000,
    );

    setState(() {
      _markers = {
        ..._markers.where((m) => m.markerId.value != 'search-result'),
        marker,
      };

      _suggestions = [];
    });

    await _moveCameraTo(target);

    final nearestGov = _nearestGovernorate(target);

    if (nearestGov != null) {
      _selectedGovKey = nearestGov;

      _rebuildPolygons();
    }

    final displayName = place.nameEn.isNotEmpty
        ? '${place.nameEn} / ${place.nameAr}'
        : place.nameAr;

    _showRouteSheet(target, displayName);
  }

  @override
  void initState() {
    super.initState();

    // نحمّل الـ GeoJSON
    _loadGeoJson();

    _loadPlacesDb(); // ⬅⬅ جديد

    _loadFlightIcon();

    // لو التخطيط مسموح (user) نعرض كرت الأسئلة فوق الخريطة
    _showQuickQuestions = _planningEnabled;
  }

  /// رجع نص عربي/إنجليزي في سطر واحد
  String _bi(String ar, String en) => '$ar / $en';

  String _placeTypeLabel(PlaceType t) {
    switch (t) {
      case PlaceType.beach:
        return 'أماكن بحرية / Beach spots';

      case PlaceType.mountain:
        return 'أماكن جبلية / Mountain spots';

      case PlaceType.historic:
        return 'أماكن تاريخية / Historic spots';

      case PlaceType.desert:
        return 'أماكن صحراوية / Desert spots';

      case PlaceType.hotel:
        return 'فنادق / Hotels';

      case PlaceType.restaurant:
        return 'مطاعم / Restaurants';

      case PlaceType.cafe:
        return 'كوفيهات / Cafés';

      case PlaceType.industrial:
        return 'أماكن صناعية / Industrial spots';

      case PlaceType.general:
      default:
        return 'أماكن عامة / General spots';
    }
  }

  /// فلترة الأماكن حسب نوع المكان + المحافظة الحالية
  /// فلترة الأماكن حسب نوع المكان + المحافظة الحالية

  // =====================================================
  // 🔍 البحث في الخريطة
  // =====================================================
  void _onSearchSubmitted(String value) async {
    if (_mapLocked) {
      _showLockedSnack();
      return;
    }
    final query = value.trim().toLowerCase();
    if (query.isEmpty) return;
    // 1) نحاول نلقى "مكان سياحي" من اللي في _allPlaces
    Place? foundPlace;
    for (final p in _allPlaces) {
      if (p.nameAr.contains(value) || p.nameEn.toLowerCase().contains(query)) {
        foundPlace = p;
        break;
      }
    }
    if (foundPlace != null) {
      _selectedGovKey = foundPlace.govKey;
      _rebuildPolygons();
      await _handlePlaceSelection(foundPlace);
      return;
    }
    // 2) نحاول نلقى محافظة بالاسم
    GovInfo? foundGov;
    for (final g in _governorates) {
      if (g.nameAr.contains(value) || g.nameEn.toLowerCase().contains(query)) {
        foundGov = g;
        break;
      }
    }
    if (foundGov != null) {
      _onGovernorateSelected(foundGov.key);
      return;
    }
    // 3) 🔍 بحث عام بأي مكان في عُمان باستخدام geocoding
    final ok = await _searchAnyLocation(value);
    if (ok) return;
    // 4) ما لقينا شي
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: kDarkBeige,
        content: Text(
          'ما لقينا مكان أو محافظة بهذا الاسم 😅',
          style: TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  /// بحث عام بأي اسم (قرية / حي / جبل ...) باستخدام Google Geocoding
  Future<bool> _searchAnyLocation(String text) async {
    try {
      // نحاول نخلي Google يفهم النص

      final locations = await geocoding.locationFromAddress(text);

      if (locations.isEmpty) return false;

      final loc = locations.first;

      final target = LatLng(loc.latitude, loc.longitude);

      // ماركر للبحث

      final searchMarker = Marker(
        markerId: const MarkerId('search-result'),
        position: target,
        infoWindow: InfoWindow(title: text),
        zIndex: 9000,
      );

      setState(() {
        _markers = {
          ..._markers.where((m) => m.markerId.value != 'search-result'),
          searchMarker,
        };
      });

      // تحريك الكاميرا

      await _moveCameraTo(target);

      // تحديد أقرب محافظة وتلوينها

      final nearestGov = _nearestGovernorate(target);

      if (nearestGov != null) {
        _selectedGovKey = nearestGov;

        _rebuildPolygons();
      }

      // عرض BottomSheet للمسار

      _showRouteSheet(target, text);

      return true;
    } catch (e) {
      debugPrint('searchAnyLocation error: $e');

      return false;
    }
  }

  /// تحريك الكاميرا لنقطة معيّنة
  Future<void> _moveCameraTo(LatLng target) async {
    if (_map == null) return;
    _currentZoom = 13;
    await _map!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: _currentZoom),
      ),
    );
  }

  /// إيجاد أقرب محافظة للإحداثيات المعطاة
  String? _nearestGovernorate(LatLng point) {
    if (_govCenters.isEmpty) return null;
    String? bestKey;
    double? bestDistance;
    _govCenters.forEach((key, center) {
      final d = Geolocator.distanceBetween(
        point.latitude,
        point.longitude,
        center.latitude,
        center.longitude,
      );
      if (bestDistance == null || d < bestDistance!) {
        bestDistance = d;
        bestKey = key;
      }
    });
    return bestKey;
  }

  /// BottomSheet يفتح للمستخدم خيار عرض المسار في Google Maps
  void _showRouteSheet(LatLng target, String name) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'تودين مشاهدة المسار في Google Maps؟',
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1'
                    '&destination=${target.latitude},${target.longitude}'
                    '&travelmode=driving',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                icon: const Icon(Icons.directions),
                label: const Text(
                  'عرض المسار',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// تطبيع اسم المحافظة ليصير key ثابت
  String _norm(String s) {
    return s.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
  }

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

  void _rebuildPolygons() {
    final Set<Polygon> polys = {};

    const normalBorder = Color(0xFF7B30FF); // حدود بنفسجي

    const normalFill = Color(0xFF7B30FF); // تعبئة بنفسجي

    const selectedBorder = Color(0xFF00BFA6);

    const selectedFill = Color(0xFF00BFA6);

    for (int i = 0; i < _polyData.length; i++) {
      final d = _polyData[i];

      final bool selected = d.govKey == _selectedGovKey;

      polys.add(
        Polygon(
          polygonId: PolygonId('polygon-${d.govKey}-$i'),
          points: d.points,
          strokeWidth: selected ? 4 : 2,
          strokeColor:
              selected ? selectedBorder : normalBorder.withOpacity(0.9),
          fillColor: selected
              ? selectedFill.withOpacity(0.25)
              : normalFill.withOpacity(0.12),
          consumeTapEvents: true,
          onTap: () {
            if (_mapLocked) {
              _showLockedSnack();
            } else {
              _onGovernorateSelected(d.govKey);
            }
          },
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
              const SnackBar(
                backgroundColor: kDarkBeige,
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
          const SnackBar(
            backgroundColor: kDarkBeige,
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

  /// لما نختار محافظة من التبويبات أو من الخريطة

  void _onGovernorateSelected(String govKey) {
    // ✋ لو الخريطة مقفولة (كرت الأسئلة ظاهر) → لا نسمح بالتغيير

    if (_mapLocked) {
      _showLockedSnack();

      return;
    }

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

    // ⭐ إذا التخطيط مفعّل → افتح شاشة المحافظة (مطاعم + فنادق + أماكن سياحية)

    if (_planningEnabled) {
      _openGovernoratePlaces(govKey);
    }
  }

  /// فتح شاشة المحافظة (GovernoratePlacesScreen)

  void _openGovernoratePlaces(String govKey) {
    final gov = _governorates.firstWhere((g) => g.key == govKey);

    // ✅ نجيب الأماكن من kGovPlaces (نوعها GovPlace)

    final govPlaces = kGovPlaces.where((p) => p.govKey == govKey).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GovernoratePlacesScreen(
          govKey: govKey,
          titleAr: gov.nameAr,
          titleEn: gov.nameEn,
          places: govPlaces,
        ),
      ),
    );
  }

  /// مسافة مركز المحافظة من موقعي (لنص قصير يظهر على التبويب)
  /// دالة حساب المسافة بين موقعي وبين أي مكان
  String _distanceText(LatLng target) {
    if (_myLocation == null) {
      return 'حدد موقعك لعرض المسافة / Enable location to show distance';
    }

    final meters = Geolocator.distanceBetween(
      _myLocation!.latitude,
      _myLocation!.longitude,
      target.latitude,
      target.longitude,
    );

    final km = meters / 1000.0;

    if (km < 1) {
      return '≈ ${meters.round()} م من موقعي';
    } else {
      return '≈ ${km.toStringAsFixed(1)} كم من موقعي';
    }
  }

  /// شاشة السؤال الأولى: السماح بالموقع (تُستدعى فقط في وضع التخطيط)
  Future<void> _askLocationPermissionSheet() async {
    // ⭐ لو التخطيط مقفول (زائر)، لا تفتحي أي شيء
    if (!_planningEnabled) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: kBeige,
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
                    // بعد الموقع نفتح نوع المكان + الوجهات (فقط لو التخطيط شغّال)
                    if (_planningEnabled) {
                      _openPlacesSheet();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkBeige,
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
                  if (_planningEnabled) {
                    _openPlacesSheet();
                  }
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

// كرت صغير فوق الخريطة لأسئلة الخطة + زر تخطي
  Widget _buildQuickQuestionCard(BuildContext context) {
    // لو التخطيط مقفول أو المستخدم سكّر الكرت -> لا نعرض شيء
    if (!_planningEnabled || !_showQuickQuestions) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.35,
      left: 16,
      right: 16,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kBeige,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'هذه الأسئلة بتساعدنا نجهز لك خطة زيارة للمحافظة اللي تختارها 👇\n'
                'These quick questions help us prepare a visit plan for you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    // نخفي الكرت
                    setState(() => _showQuickQuestions = false);
                    // نفتح شيت السماح بالموقع + الأماكن
                    await _askLocationPermissionSheet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkBeige,
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
              const SizedBox(height: 6),
              TextButton(
                onPressed: () {
                  // يخفي الكرت ويخلي المستخدم يستكشف الخريطة بنفسه
                  setState(() => _showQuickQuestions = false);
                },
                child: const Text(
                  'تخطي الآن – أستكشف الخريطة بنفسي',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestionsOverlay() {
    if (_suggestions.isEmpty || _mapLocked) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 110, // عدّليها لو عندك AppBar أعلى

      left: 16,

      right: 16,

      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 260,
          ),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final p = _suggestions[index];

              final title = p.nameAr.isNotEmpty ? p.nameAr : p.nameEn;

              final subtitle =
                  p.nameAr.isNotEmpty && p.nameEn.isNotEmpty ? p.nameEn : '';

              return ListTile(
                onTap: () => _goToSearchPlace(p),
                title: Text(
                  title,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                subtitle: subtitle.isEmpty
                    ? null
                    : Text(
                        subtitle,
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// شاشة اختيار نوع المكان + الوجهات (مع معالجة الـ overflow + زر رجوع)
  // دالة فتح ورقة الأسئلة + قائمة الأماكن

  Future<void> _openPlacesSheet() async {
    if (_mapLocked) {
      _showLockedSnack();

      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        // نستخدم StatefulBuilder علشان نقدر نحدّث محتوى البوتوم شيت

        return StatefulBuilder(
          builder: (context, setModalState) {
            // الأماكن حسب المحافظة + نوع المكان المختار

            final placesToShow = _filteredPlaces();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // الخط الصغير فوق (handle)

                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),

                      const Text(
                        'Map',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'تم تحديد موقعك، سيتم عرض المسافة والوقت لكل وجهة.',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // =======================

                      //  سؤال ١: نوع المكان

                      // =======================

                      const Text(
                        'السؤال ١: ما نوع الأماكن التي تحب تزورها أولاً؟',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          // عام

                          _buildTypeChip(
                            titleAr: 'أماكن سياحية عامة',
                            titleEn: 'General tourist places',
                            selected: _selectedType == null,
                            onTap: () {
                              setModalState(() {
                                _selectedType = null;
                              });

                              _goToTripPlannerAfterTypeSelected(null);
                            },
                          ),

                          // بحري

                          _buildTypeChip(
                            titleAr: 'أماكن بحرية',
                            titleEn: 'Beach spots',
                            selected: _selectedType == PlaceType.beach,
                            onTap: () {
                              setModalState(() {
                                _selectedType = PlaceType.beach;
                              });

                              _goToTripPlannerAfterTypeSelected(
                                  PlaceType.beach);
                            },
                          ),

                          // جبلي

                          _buildTypeChip(
                            titleAr: 'أماكن جبلية',
                            titleEn: 'Mountain spots',
                            selected: _selectedType == PlaceType.mountain,
                            onTap: () {
                              setModalState(() {
                                _selectedType = PlaceType.mountain;
                              });

                              _goToTripPlannerAfterTypeSelected(
                                  PlaceType.mountain);
                            },
                          ),

                          // صناعي

                          _buildTypeChip(
                            titleAr: 'أماكن صناعية',
                            titleEn: 'Industrial spots',
                            selected: _selectedType == PlaceType.industrial,
                            onTap: () {
                              setModalState(() {
                                _selectedType = PlaceType.industrial;
                              });

                              _goToTripPlannerAfterTypeSelected(
                                  PlaceType.industrial);
                            },
                          ),

                          // تاريخي

                          _buildTypeChip(
                            titleAr: 'أماكن تاريخية',
                            titleEn: 'Historic spots',
                            selected: _selectedType == PlaceType.historic,
                            onTap: () {
                              setModalState(() {
                                _selectedType = PlaceType.historic;
                              });

                              _goToTripPlannerAfterTypeSelected(
                                  PlaceType.historic);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // =======================

                      //  سؤال ٢: قائمة الأماكن

                      // =======================

                      const Text(
                        'السؤال ٢: اختر المكان الذي يناسبك:',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (placesToShow.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'لا توجد أماكن لهذا النوع في هذه المحافظة حاليًا.',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: placesToShow.length,
                          itemBuilder: (context, index) {
                            final p = placesToShow[index];

                            return _buildQuestionPlaceCard(p);
                          },
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

  // زر نوع المكان في سؤال ١

  Widget _buildTypeChip({
    required String titleAr,
    required String titleEn,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? kDarkBeige : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? kDarkBeige : Colors.grey.shade300,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$titleEn / $titleAr',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

// كرت المكان في سؤال ٢

  Widget _buildQuestionPlaceCard(Place p) {
    final alreadyInTrip = _isInTrip(p);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // لما تختار المكان يروح له على الخريطة

          _map?.animateCamera(
            CameraUpdate.newLatLngZoom(p.position, 14),
          );

          Navigator.pop(context);
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
                right: Radius.circular(0),
              ),
              child: Image.asset(
                p.imageAsset,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.nameAr} / ${p.nameEn}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '~ يبعد كم من موقعك (تقدير المسافة)',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          await _addPlaceToTripWithSheet(p);
                        },
                        icon: Icon(
                          alreadyInTrip ? Icons.check : Icons.add,
                        ),
                        label: Text(
                          alreadyInTrip ? 'مضاف إلى رحلتي' : 'إضافة إلى رحلتي',
                          style: const TextStyle(fontFamily: 'Tajawal'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// شيت لتفاصيل خطة الزيارة لمكان معيّن

  Future<void> _openVisitPlanSheet(Place place) async {
    final TextEditingController durationController = TextEditingController();

    // خيارات Q4

    bool wantHotels = true;

    bool wantRestaurants = true;

    bool wantSittings = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Text(
                      'خطة زيارتك لـ ${place.nameAr} (${_placeTypeLabel(place.type)})',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.start,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Your visit plan to ${place.nameEn}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Q3: المدة

                    const Text(
                      'السؤال ٣: كم تنوي تجلس في هذا المكان؟',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Q3: How long do you plan to stay there?',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: '(مثلاً 3) Enter number',
                              labelStyle: TextStyle(fontFamily: 'Tajawal'),
                              border: OutlineInputBorder(),
                            ),
                            style: const TextStyle(fontFamily: 'Tajawal'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ساعات / Hours',
                          style: TextStyle(fontFamily: 'Tajawal'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Q4: اقتراحات

                    const Text(
                      'السؤال ٤: تحت نقترح لك:',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Q4: Would you like us to suggest',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 8),

                    CheckboxListTile(
                      value: wantHotels,
                      onChanged: (v) {
                        setModalState(() => wantHotels = v ?? false);
                      },
                      title: const Text(
                        'فنادق قريبة / Nearby hotels',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    CheckboxListTile(
                      value: wantRestaurants,
                      onChanged: (v) {
                        setModalState(() => wantRestaurants = v ?? false);
                      },
                      title: const Text(
                        'مطاعم قريبة / Nearby restaurants',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    CheckboxListTile(
                      value: wantSittings,
                      onChanged: (v) {
                        setModalState(() => wantSittings = v ?? false);
                      },
                      title: const Text(
                        'أماكن جلسات قريبة / Nearby sitting areas',
                        style: TextStyle(fontFamily: 'Tajawal'),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkBeige,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          final text = durationController.text.trim();

                          if (text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: kDarkBeige,
                                content: Text(
                                  'اكتبي مدة الزيارة أولًا 😊',
                                  style: TextStyle(fontFamily: 'Tajawal'),
                                ),
                              ),
                            );

                            return;
                          }

                          final double hours = double.tryParse(text) ?? 0;

                          final String durationText = '$text ساعات';

                          // نصنع الخطة

                          final plan = MapTripPlan(
                            place: place,
                            durationHours: hours,
                            durationText: durationText,
                            wantHotels: wantHotels,
                            wantRestaurants: wantRestaurants,
                            wantSittings: wantSittings,
                            createdAt: DateTime.now(),
                            day: 1,
                          );

                          // لو حابة تحتفظي بكل الخطط في الذاكرة برضه:

                          setState(() {
                            _savedPlans.add(plan);
                          });

                          // نغلق الشيت

                          Navigator.of(ctx).pop();

                          // نفتح صفحة "رحلتي" ومعنا كل الخطط الحالية

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => YourTripScreen(
                                plans: _savedPlans,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Confirm plan / تأكيد الخطة',
                          style: TextStyle(fontFamily: 'Tajawal'),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// التعامل مع اختيار المكان: نقترح الأقرب لو في فرق واضح
  /// التعامل مع اختيار المكان: نقترح الأقرب لو في فرق واضح
  Future<void> _handlePlaceSelection(Place selected) async {
    // لو التخطيط مقفول (ضيف) 👉 بس نروح للمكان بدون أي شيت أو اقتراح

    if (!_planningEnabled) {
      await _goToPlace(selected);

      return;
    }

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
          selected,
          nearest,
          selectedMeters,
          nearestMeters,
        );

        return;
      }
    }

    // لو ما في اقتراح أو مافي فرق كبير، نكمل عادي

    await _goToPlace(finalPlace);

    // ✅ افتح شيت "خطة الزيارة" الجديد

    if (_planningEnabled) {
      await _openVisitPlanSheet(finalPlace);
    }
  }

  /// شيت اقتراح مكان أقرب
  /// شيت اقتراح مكان أقرب
  Future<void> _askCloserSuggestion(
    Place chosen,
    Place nearest,
    double chosenMeters,
    double nearestMeters,
  ) async {
    // لو التخطيط مقفول أساساً (ضيف) ما نعرض شيت الاقتراح
    if (!_planningEnabled) {
      await _goToPlace(chosen);
      return;
    }

    final chosenKm = (chosenMeters / 1000.0).toStringAsFixed(1);
    final nearestKm = (nearestMeters / 1000.0).toStringAsFixed(1);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: kBeige, // بيج فاتح
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
                  color: kBeige,
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
                    if (_planningEnabled) {
                      await _openPlanSheet(nearest);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkBeige, // بيج غامق
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
                  if (_planningEnabled) {
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

  /// BottomSheet لخطّة الزيارة (سؤال الساعات/الأيام + فنادق + مطاعم + جلسات)
  /// وبعد الحفظ يفتح صفحة "رحلاتي" أو "خطتي"
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
      backgroundColor: kBeige,
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

                          final plan = MapTripPlan(
                            place: p,
                            durationHours: durationHours,
                            durationText: durationText,
                            wantHotels: wantHotels,
                            wantRestaurants: wantRestaurants,
                            wantSittings: wantSittings,
                            createdAt: DateTime.now(),
                            day: 1,
                          );
                          _savedPlans.add(plan);

                          // نغلق الشيت

                          Navigator.of(ctx).pop();

// نفتح صفحة "رحلتي" ونرسل قائمة الخطط عبر الـ arguments

                          Navigator.of(context).pushNamed(
                            '/my_trip',
                            arguments: _savedPlans,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kDarkBeige,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("خريطة عُمان السياحية"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'رحلتي',
            onPressed: () {
              // لو ما في ولا خطة

              if (kTripPlans.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ما أضفتِ أي أماكن إلى رحلتك حتى الآن 😊',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  ),
                );

                return;
              }

              // إذا في خطط → افتح صفحة رحلتي

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => YourTripScreen(plans: kTripPlans),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ===== الخريطة =====

          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 7.0),
            polygons: _polygons,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            cameraTargetBounds: CameraTargetBounds(_omanBounds),
            minMaxZoomPreference: const MinMaxZoomPreference(6.5, 12),
            scrollGesturesEnabled: !_mapLocked,
            zoomGesturesEnabled: !_mapLocked,
            rotateGesturesEnabled: !_mapLocked,
            tiltGesturesEnabled: !_mapLocked,
            onMapCreated: (c) {
              _map = c;

              Future.delayed(const Duration(milliseconds: 300), () {
                _map!.animateCamera(
                  CameraUpdate.newLatLngBounds(_omanBounds, 32),
                );
              });
            },
            onCameraMove: (pos) {
              _currentZoom = pos.zoom;

              if (!_omanBounds.contains(pos.target)) {
                _map!.animateCamera(
                  CameraUpdate.newLatLngBounds(_omanBounds, 10),
                );
              }
            },
          ),

          // ===== كرت الأسئلة السريع =====

          _buildQuickQuestionCard(context),

          // ===== شريط البحث + اسم المحافظة =====

          Positioned(
            top: 16,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // حقل البحث

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSearchSubmitted,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search),
                      hintText:
                          'ابحث عن مكان أو ولاية (مثلاً: الصويحره، صحار...)',
                      hintStyle: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // عنوان المحافظة المحددة

                Container(
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
              ],
            ),
          ),

          // ===== الاقتراحات تحت شريط البحث =====

          _buildSearchSuggestionsOverlay(),

          // ===== تبويبات المحافظات + المسافة =====

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
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _governorates.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final g = _governorates[index];

                      final selected = g.key == _selectedGovKey;

                      return GestureDetector(
                        onTap: () {
                          if (_mapLocked) {
                            _showLockedSnack();
                          } else {
                            _onGovernorateSelected(g.key);
                          }
                        },
                        child: Container(
                          width: 230,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF5E2BFF)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF5E2BFF)
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${g.nameAr} / ${g.nameEn}',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      selected ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _distanceText(
                                  _govCenters[g.key] ?? const LatLng(0, 0),
                                ),
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11,
                                  color: selected
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ===== أزرار التكبير + موقعي =====

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
