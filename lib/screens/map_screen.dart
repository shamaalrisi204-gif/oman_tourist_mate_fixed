// lib/screens/map_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:webview_flutter/webview_flutter.dart';

import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _ctrl;

  StreamSubscription<Position>? _sub;

  bool _tracking = false;

  @override
  void initState() {
    super.initState();

    _initWeb();
  }

  Future<void> _initWeb() async {
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            // لو حابّة تتأكدي أن الدالة موجودة في صفحة الـ HTML

            _ctrl.runJavaScript(
                "console.log('✅ Flutter connected, waiting for __nativeLocation');");
          },
        ),
      )
      ..loadFlutterAsset('assets/web/oman_map_inline.html');

    setState(() {});
  }

  Future<bool> _ensurePermission() async {
    // تشغيل خدمات الموقع

    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();

      return false;
    }

    // إذن الوصول للموقع

    LocationPermission p = await Geolocator.checkPermission();

    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }

    if (p == LocationPermission.denied ||
        p == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> _startTracking() async {
    if (!await _ensurePermission()) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فعّلي GPS واسمحي بإذن الموقع')),
      );

      return;
    }

    // أولاً: آخر نقطة حالية

    final now = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    _sendToWeb(now);

    // ثانياً: نبدأ الستريم للتتبع الحي

    _sub?.cancel();

    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).listen(_sendToWeb);

    setState(() => _tracking = true);
  }

  Future<void> _stopTracking() async {
    await _sub?.cancel();

    _sub = null;

    setState(() => _tracking = false);
  }

  void _sendToWeb(Position p) {
    // 👈 شوفي هذه القيم في Debug Console

    print(
        "📍 FLUTTER POS => lat=${p.latitude}, lon=${p.longitude}, acc=${p.accuracy}");

    final lat = p.latitude.toStringAsFixed(6);

    final lon = p.longitude.toStringAsFixed(6);

    final acc = p.accuracy.toStringAsFixed(1);

    // نرسلها للـ HTML بنفس الترتيب lat, lon

    final js =
        "window.__nativeLocation && window.__nativeLocation($lat, $lon, $acc);";

    _ctrl.runJavaScript(js);
  }

  @override
  void dispose() {
    _sub?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة سلطنة عُمان'),
        actions: [
          IconButton(
            tooltip: 'إعادة الضبط',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _ctrl.runJavaScript('window.__resetMap && window.__resetMap();');
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _tracking ? null : _startTracking,
                icon: const Icon(Icons.my_location),
                label: const Text('موقعي'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _tracking ? _stopTracking : null,
                icon: const Icon(Icons.pause_circle_outline),
                label: const Text('إيقاف التتبع'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    try {
      return WebViewWidget(controller: _ctrl);
    } catch (_) {
      return const Center(child: CircularProgressIndicator());
    }
  }
}
