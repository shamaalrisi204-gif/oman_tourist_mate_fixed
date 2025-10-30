import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GovernoratesMapWebView extends StatefulWidget {
  const GovernoratesMapWebView({super.key});
  @override
  State<GovernoratesMapWebView> createState() => _GovernoratesMapWebViewState();
}

class _GovernoratesMapWebViewState extends State<GovernoratesMapWebView> {
  late final WebViewController _controller;
  String? _selectedGov;
  // أمثلة أماكن سياحية لكل محافظة (بدّليها ببياناتك لاحقًا)
  final Map<String, List<String>> _tourismByGov = const {
    'مسقط': ['المتحف الوطني', 'دار الأوبرا', 'قلعة الجلالي', 'سوق مطرح'],
    'ظفار': ['شاطئ المغسيل', 'وادي دربات', 'شلالات صلالة'],
    'مسندم': ['فيوردات مسندم', 'رحلة الداو والدلافين'],
    'الداخلية': ['قلعة نزوى', 'جبل شمس', 'كهف الهوته'],
    'جنوب الشرقية': ['رمال الشرقية', 'رأس الحد'],
    'شمال الباطنة': ['قلعة صحار', 'كورنيش صحار'],
    // أضيفي بقية المحافظات…
  };
  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'GOV_CHANNEL',
        onMessageReceived: (JavaScriptMessage msg) {
          final nameAr = msg.message.trim();
          setState(() => _selectedGov = nameAr.isEmpty ? null : nameAr);
          if (nameAr.isNotEmpty) {
            _showPlacesBottomSheet(nameAr);
          }
        },
      )
      ..setBackgroundColor(const Color(0x00000000))
      ..loadFlutterAsset('assets/web/leaflet_map.html');
  }

  void _showPlacesBottomSheet(String govAr) {
    final items = _tourismByGov[govAr] ?? const <String>[];
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(govAr, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Text('لا توجد بيانات — أضيفي أماكن لهذه المحافظة.')
              else
                ...items.map((p) => ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(p),
                      onTap: () {
                        // TODO: افتحي شاشة تفاصيل المكان لو حبيتي
                        Navigator.pop(context);
                      },
                    )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // لأن HTML RTL، نخلي العنوان RTL
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('خريطة عُمان'),
          actions: [
            if (_selectedGov != null)
              Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Text(_selectedGov!,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
