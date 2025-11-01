import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OmanMapAssetWebViewPage extends StatefulWidget {
  const OmanMapAssetWebViewPage({super.key});
  @override
  State<OmanMapAssetWebViewPage> createState() =>
      _OmanMapAssetWebViewPageState();
}

class _OmanMapAssetWebViewPageState extends State<OmanMapAssetWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
            onPageFinished: (_) => setState(() => _isLoading = false)),
      )
      ..loadFlutterAsset('assets/web/oman_svg_map.html'); // ⬅️ من الأصول
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('خريطة سلطنة عُمان (محلي)')),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
