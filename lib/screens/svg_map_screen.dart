import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SvgMapScreen extends StatefulWidget {
  const SvgMapScreen({super.key});
  @override
  State<SvgMapScreen> createState() => _SvgMapScreenState();
}

class _SvgMapScreenState extends State<SvgMapScreen> {
  late final WebViewController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      // نحمل ملف الـ HTML كأصل (Asset)
      ..loadFlutterAsset('assets/web/oman_svg_map.html');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خريطة SVG – محافظات عُمان')),
      body: WebViewWidget(controller: _ctrl),
    );
  }
}
