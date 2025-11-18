import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/prefs.dart';

class TravelTipsScreen extends StatefulWidget {
  const TravelTipsScreen({super.key});

  @override
  State<TravelTipsScreen> createState() => _TravelTipsScreenState();
}

/// موديل لقسم من الإرشادات
class _TipSection {
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String imageAsset;

  const _TipSection({
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.imageAsset,
  });
}

class _TravelTipsScreenState extends State<TravelTipsScreen> {
  bool _isArabic = true;

  static const Color _primary = Color(0xFF5E2BFF);
  static const Color _background = Color(0xFFF3EED9);

  // الأقسام (عدلي النصوص والصور على راحتك)
  final List<_TipSection> _sections = const [
    _TipSection(
      titleAr: 'اكتشاف جمال عُمان: إرشادات السلامة',
      titleEn: 'Discover Oman: Safety Tips',
      bodyAr:
          'تُعد سلطنة عُمان من أكثر البلدان أمانًا، لكن ننصح دائمًا باتباع إرشادات السلامة العامة، '
          'مثل الانتباه لمقتنياتك الشخصية، واحترام التعليمات في المناطق السياحية والطرقات.',
      bodyEn:
          'Oman is one of the safest destinations, but it is still recommended to '
          'follow general safety tips, keep an eye on your belongings, and respect '
          'local rules in tourist areas and roads.',
      imageAsset: 'assets/tips/safety.jpg',
    ),
    _TipSection(
      titleAr: 'تعرّف على العملة المحلية',
      titleEn: 'Get to Know the Local Currency',
      bodyAr:
          'الريال العُماني هو العملة الرسمية في السلطنة، وينقسم إلى 1000 بيسة. '
          'تتوفر أجهزة الصرّاف الآلي في معظم المراكز التجارية والمطارات، '
          'ويمكن استخدام البطاقات البنكية في أغلب المحلات والفنادق.',
      bodyEn:
          'The Omani Rial (OMR) is the official currency. ATMs are widely available '
          'in malls and airports, and most shops and hotels accept debit and credit cards.',
      imageAsset: 'assets/tips/currency.jpg',
    ),
    _TipSection(
      titleAr: 'إتيكيت السفر واحترام الثقافة المحلية',
      titleEn: 'Travel Etiquette & Local Culture',
      bodyAr:
          'يُفضّل ارتداء ملابس محتشمة في الأماكن العامة، خصوصًا في المواقع الدينية والتاريخية. '
          'استأذن قبل تصوير الأشخاص، واحرص على الحفاظ على خصوصيتهم وراحتهم أثناء زيارتك.',
      bodyEn:
          'Dress modestly in public spaces, especially near mosques and heritage sites. '
          'Always ask permission before photographing people and respect their privacy.',
      imageAsset: 'assets/tips/etiquette.jpg',
    ),
    _TipSection(
      titleAr: 'أرقام قد تهمّك في حالات الطوارئ',
      titleEn: 'Useful Numbers & Emergencies',
      bodyAr:
          'في حالات الطوارئ يمكنك الاتصال على الرقم 9999 لطلب الشرطة أو الإسعاف. '
          'كما تتوفر خدمات المساعدة على الطرق عبر شركات متخصصة عديدة في جميع أنحاء السلطنة.',
      bodyEn:
          'In case of emergency, dial 9999 for police or ambulance. Roadside assistance '
          'services are also available through several companies across the country.',
      imageAsset: 'assets/tips/emergency.jpg',
    ),
    _TipSection(
      titleAr: 'التوفير الضريبي والتسوّق',
      titleEn: 'Tax Saving & Shopping',
      bodyAr:
          'بإمكان الزوّار الاستفادة من خدمة استرداد الضريبة على المشتريات من بعض المتاجر المعتمدة. '
          'احتفظ بفواتيرك وتحقق من نقاط الاسترداد في المطارات أو المراكز المحددة.',
      bodyEn:
          'Visitors can benefit from tax refund services at selected stores. Keep your receipts '
          'and check the refund counters at airports or designated points.',
      imageAsset: 'assets/tips/tax_refund.jpg',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final ar = await Prefs.isArabic;
    if (!mounted) return;
    setState(() => _isArabic = ar);
  }

  Future<void> _toggleLanguage() async {
    final app = AppStateProvider.of(context);
    final newCode = _isArabic ? 'en' : 'ar';
    await app.setLanguage(newCode);
    if (!mounted) return;
    setState(() => _isArabic = !_isArabic);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isArabic ? 'الإرشادات والنصائح' : 'Travel Tips & Safety';

    final langBtn = _isArabic ? 'English' : 'العربية';

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            title,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            TextButton(
              onPressed: _toggleLanguage,
              child: Text(
                langBtn,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildHeroHeader(),
            const SizedBox(height: 16),
            ..._sections.map(_buildSectionCard),
          ],
        ),
      ),
    );
  }

  // ====== صورة هيرو في الأعلى ======
  Widget _buildHeroHeader() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/tips/header.jpg', // غيّريها لصورة تناسبك
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.05),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 18,
              child: Text(
                _isArabic
                    ? 'استعد لرحلتك في عُمان مع إرشادات مهمة وتجربة آمنة وممتعة.'
                    : 'Get ready for your trip to Oman with helpful tips and a safe, enjoyable stay.',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== كرت قسم واحد مع صورة + نص ======
  Widget _buildSectionCard(_TipSection section) {
    final title = _isArabic ? section.titleAr : section.titleEn;
    final body = _isArabic ? section.bodyAr : section.bodyEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.asset(
              section.imageAsset,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
