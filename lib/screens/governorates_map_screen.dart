// lib/screens/governorates_map_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GovernoratesMapScreen extends StatefulWidget {
  const GovernoratesMapScreen({super.key});
  @override
  State<GovernoratesMapScreen> createState() => _GovernoratesMapScreenState();
}

class _GovernoratesMapScreenState extends State<GovernoratesMapScreen> {
  GoogleMapController? _map;
  final Set<Polygon> _polygons = {};
  // حدود عُمان العامة (لتحجيم الكاميرا)
  static final LatLngBounds _omanBounds = LatLngBounds(
    southwest: const LatLng(16.4, 52.0),
    northeast: const LatLng(26.6, 60.5),
  );
  static const CameraPosition _initial = CameraPosition(
    target: LatLng(23.6, 58.4),
    zoom: 6.3,
  );
  @override
  void initState() {
    super.initState();
    // ممكن نبني القناع بعد إنشاء الخريطة أيضاً؛ هنا نجهز أي شيء مبكرًا إذا رغبتِ.
  }

  // ========== ستايل خريطة هادئ ==========
  Future<void> _applyStyle() async {
    try {
      final style =
          await rootBundle.loadString('assets/map_styles/visit_oman_like.json');
      await _map?.setMapStyle(style);
    } catch (_) {
      // لو ما لقي الستايل تجاهلي الخطأ
    }
  }

  // ========== قراءة حلقة حدود عُمان من GeoJSON ==========
  List<LatLng> _toLatLngRing(List ring) {
    // تنسيق GeoJSON: [lng, lat]
    return ring.map<LatLng>((pt) {
      final lng = (pt[0] as num).toDouble();
      final lat = (pt[1] as num).toDouble();
      return LatLng(lat, lng);
    }).toList();
  }

  Future<List<LatLng>> _loadOmanOutline() async {
    final jsonStr =
        await rootBundle.loadString('assets/geo/oman_outline.geojson');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    // نتوقع FeatureCollection بداخلها Feature واحد من نوع Polygon أو MultiPolygon
    final features = data['features'] as List;
    if (features.isEmpty) throw 'No features in oman_outline.geojson';
    final geom = (features.first)['geometry'] as Map<String, dynamic>;
    final type = geom['type'] as String;
    // Polygon: coordinates => [ [ring1], [hole1], ...]
    // MultiPolygon: coordinates => [ [ [ring1], ... ], [ [ringX], ...] ]
    if (type == 'Polygon') {
      final coords = geom['coordinates'] as List;
      final outerRing = coords.first as List;
      return _toLatLngRing(outerRing);
    } else if (type == 'MultiPolygon') {
      final multi = geom['coordinates'] as List;
      // نأخذ أول بوليغون وأول حلقة خارجية
      final firstPolyRings = multi.first as List;
      final outerRing = firstPolyRings.first as List;
      return _toLatLngRing(outerRing);
    } else {
      throw 'Unsupported geometry type: $type';
    }
  }

  // ========== بناء القناع: مضلع ضخم + فتحة بشكل عُمان ==========
  Future<void> _buildMaskPolygon() async {
    // 1) حمّلي حدود عُمان (ring من geojson)
    final omanRing = await _loadOmanOutline();
    // 2) في خرائط جوجل لازم حلقة الثقب يكون اتجاهها (winding) عكسي لاتجاه الحلقة الخارجية.
    // أسهل حل: اعكسي ترتيب النقاط للثقب.
    final hole = List<LatLng>.from(omanRing.reversed);
    // 3) مضلع خارجي عملاق (يغطي مساحة كبيرة حول شبه الجزيرة)
    final outer = <LatLng>[
      const LatLng(35.0, 40.0), // أعلى يسار
      const LatLng(35.0, 70.0), // أعلى يمين
      const LatLng(5.0, 70.0), // أسفل يمين
      const LatLng(5.0, 40.0), // أسفل يسار
    ];
    final mask = Polygon(
      polygonId: const PolygonId('world-mask'),
      points: outer,
      holes: [hole], // <-- هنا الفتحة
      fillColor: Colors.black.withOpacity(0.30), // تعتيم حول عُمان
      strokeWidth: 0,
      zIndex: 1,
      consumeTapEvents: false,
    );
    setState(() {
      _polygons.removeWhere((p) => p.polygonId.value == 'world-mask');
      _polygons.add(mask);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة عُمان'),
        actions: [
          IconButton(
            tooltip: 'مركز على عمان',
            icon: const Icon(Icons.public),
            onPressed: () => _map
                ?.animateCamera(CameraUpdate.newLatLngBounds(_omanBounds, 28)),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: _initial,
        cameraTargetBounds: CameraTargetBounds(_omanBounds),
        minMaxZoomPreference: const MinMaxZoomPreference(5.6, 17),
        myLocationEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        polygons: _polygons,
        onMapCreated: (c) async {
          _map = c;
          await _applyStyle();
          // إبراز عمان كاملة عند البدء:
          _map?.animateCamera(CameraUpdate.newLatLngBounds(_omanBounds, 20));
          // بناء القناع بعد إنشاء الخريطة:
          await _buildMaskPolygon();
        },
      ),
    );
  }
}
