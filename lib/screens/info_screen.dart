import 'package:flutter/material.dart';

import '../core/prefs.dart';
import '../core/app_state.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  bool _isArabic = true;

  static const Color _background = Color(0xFFF3EED9);
  static const Color _cardColor = Color(0xFFE5D7B8);
  static const Color _primary = Color(0xFF5E2BFF);

  @override
  void initState() {
    super.initState();
    _loadLang();
  }

  Future<void> _loadLang() async {
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

  String t(String ar, String en) => _isArabic ? ar : en;

  void _openDetails({
    required String titleAr,
    required String titleEn,
    required String bodyAr,
    required String bodyEn,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final title = t(titleAr, titleEn);
        final body = t(bodyAr, bodyEn);
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Directionality(
            textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
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
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        t('إغلاق', 'Close'),
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = t('معلومات قد تهمك', 'Useful information');

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
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: _toggleLanguage,
              child: Text(
                _isArabic ? 'English' : 'العربية',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t(
                  'اختاري أحد الأقسام للحصول على معلومات سريعة قبل رحلتك.',
                  'Choose a section to see helpful info for your trip.',
                ),
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // ===== الكروت =====
              _infoTile(
                icon: Icons.tips_and_updates_outlined,
                title: t('الإرشادات والنصائح', 'Tips & guidelines'),
                subtitle: t(
                  'نصائح عامة للسلامة والسفر داخل عُمان.',
                  'General safety and travel tips in Oman.',
                ),
                onTap: () => _openDetails(
                  titleAr: 'الإرشادات والنصائح',
                  titleEn: 'Travel tips & guidelines',
                  bodyAr: '• احرصي على حمل هوية سارية وجواز السفر.\n'
                      '• احترمي العادات والتقاليد المحلية في اللباس والتصرف.\n'
                      '• اشربي كمية كافية من الماء خاصة في الأجواء الحارة.\n'
                      '• احتفظي بأرقام الطوارئ وأقرب سفارة لك.',
                  bodyEn: '• Always carry a valid ID and passport.\n'
                      '• Respect local customs and dress code.\n'
                      '• Stay hydrated, especially in hot weather.\n'
                      '• Keep emergency numbers and your embassy contacts.',
                ),
              ),
              const SizedBox(height: 12),
              _infoTile(
                icon: Icons.cloud_outlined,
                title: t('الطقس والمناخ', 'Weather & climate'),
                subtitle: t(
                  'لمحة عن أفضل أوقات زيارة عُمان.',
                  'Overview of the best time to visit Oman.',
                ),
                onTap: () => _openDetails(
                  titleAr: 'الطقس والمناخ',
                  titleEn: 'Weather & climate',
                  bodyAr: 'يتسم مناخ عُمان بالدفء معظم العام:\n\n'
                      '• من أكتوبر إلى إبريل: أجواء معتدلة ومناسبة للأنشطة الخارجية.\n'
                      '• الصيف: درجات حرارة أعلى، مناسبة أكثر للأنشطة البحرية.\n'
                      'تحققي دائمًا من حالة الطقس قبل التخطيط للرحلات الجبلية أو الصحراوية.',
                  bodyEn: 'Oman has generally warm weather:\n\n'
                      '• October–April: Mild temperatures, perfect for outdoor activities.\n'
                      '• Summer: Hotter weather, great for beach and sea experiences.\n'
                      'Always check the forecast before planning mountain or desert trips.',
                ),
              ),
              const SizedBox(height: 12),
              _infoTile(
                icon: Icons.article_outlined,
                title: t('الأخبار', 'News & updates'),
                subtitle: t(
                  'اطّلعي على آخر المستجدات السياحية.',
                  'Stay updated with tourism-related news.',
                ),
                onTap: () => _openDetails(
                  titleAr: 'الأخبار السياحية',
                  titleEn: 'Tourism news',
                  bodyAr:
                      'هنا يمكنك إضافة روابط أو ملخصات لأهم الأخبار السياحية '
                      'والفعاليات في عُمان، مثل المهرجانات، المواسم، أو افتتاح معالم جديدة.\n\n'
                      'يمكنك لاحقًا ربط هذه الصفحة بمصدر أخبار حقيقي أو API.',
                  bodyEn:
                      'Here you can add links or summaries of important tourism news '
                      'and events in Oman, such as festivals, seasons, or new attractions.\n\n'
                      'Later, you can connect this section to a real news source or API.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: _cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: _primary, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
