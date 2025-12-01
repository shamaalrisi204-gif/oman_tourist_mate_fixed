// lib/screens/transport_services_screen.dart

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

class TransportServicesScreen extends StatelessWidget {
  final bool isArabic;

  const TransportServicesScreen({
    super.key,
    required this.isArabic,
  });

  static const Color _background = Color(0xFFF3EED9);

  @override
  Widget build(BuildContext context) {
    final title = isArabic ? 'النقل' : 'Transport';

    final introTitle =
        isArabic ? 'خدمات النقل في عُمان' : 'Transportation in Oman';

    final introText = isArabic
        ? 'جميع وسائل المواصلات متوفرة في عُمان، بدءاً من الحافلات العامة '
            'وسيارات الأجرة ووصولاً إلى وسائل النقل الخاصة مثل السيارات المستأجرة '
            'مع سائق أو بدون سائق، وخدمات التوصيل من وإلى المطار والرحلات بين المدن.'
        : 'All means of transportation are available in Oman: public buses, '
            'taxis, rental cars with or without driver, and airport / intercity transfers.';

    final taxiSectionTitle =
        isArabic ? 'تطبيقات التاكسي المحلية' : 'Local taxi apps';

    final taxiWebSectionTitle = isArabic
        ? 'شركات / مواقع للحجوزات والنقل'
        : 'Transfer & taxi companies';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ===== Hero =====

          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/transport/airport.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.black.withOpacity(0.05),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          introTitle,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          introText,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ===== عنوان التطبيقات =====

          Text(
            taxiSectionTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            isArabic
                ? 'استخدمي هذه التطبيقات لحجز سيارة تاكسي داخل المدن أو من وإلى المطار.'
                : 'Use these apps to book licensed taxis inside cities or to/from the airport.',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),

          const SizedBox(height: 12),

          // ===== كروت التطبيقات =====

          _TaxiCard(
            isArabic: isArabic,
            titleAr: 'OmanTaxi',
            titleEn: 'OmanTaxi',
            link: 'https://apps.apple.com/us/app/omantaxi/id1117668380',
            descriptionAr: 'تطبيق محلي لحجز تاكسي مرخّص داخل المدن أو للمطار.',
            descriptionEn: 'Local taxi booking app for city and airport rides.',
          ),

          _TaxiCard(
            isArabic: isArabic,
            titleAr: 'Otaxi',
            titleEn: 'Otaxi',
            link: 'https://play.google.com/store/apps/details?id=com.otaxi',
            descriptionAr: 'تطبيق سريع وسهل لحجز التاكسي في مسقط.',
            descriptionEn: 'Fast and easy taxi booking in Muscat.',
          ),

          _TaxiCard(
            isArabic: isArabic,
            titleAr: 'TaxiF',
            titleEn: 'TaxiF',
            link: 'https://taxif.com',
            descriptionAr: 'خدمة تاكسي ذكية وسريعة داخل عمان.',
            descriptionEn: 'Smart and fast taxi service in Oman.',
          ),

          _TaxiCard(
            isArabic: isArabic,
            titleAr: 'HalaTaxi',
            titleEn: 'HalaTaxi',
            link: 'https://htaxi.app',
            descriptionAr: 'تطبيق “super-app” للنقل داخل السلطنة.',
            descriptionEn: 'A transportation super-app in Oman.',
          ),

          const SizedBox(height: 20),

          // ===== شركات ومواقع =====

          Text(
            taxiWebSectionTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 8),

          _TaxiCard(
            isArabic: isArabic,
            titleAr: 'TaxiMatcher',
            titleEn: 'TaxiMatcher',
            link: 'https://www.taximatcher.com',
            descriptionAr: 'حجز تاكسي / VIP أو ميني باص للمطار أو أي وجهة.',
            descriptionEn: 'Taxi / VIP / Minibus booking for airport or city.',
          ),

          _TaxiCard(
            isArabic: isArabic,
            titleAr: 'Tasleem Taxi',
            titleEn: 'Tasleem Taxi',
            link: 'tel:90610066',
            descriptionAr: 'خدمة تاكسي محلية في مسقط — للاتصال: 9061 0066.',
            descriptionEn: 'Local taxi service in Muscat — Call: 90610066.',
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isArabic
                  ? 'ملاحظة: يُفضّل دائماً التأكد من الأسعار والتوافر داخل التطبيق أو بالاتصال قبل الحجز.'
                  : 'Note: Always check prices and availability before booking.',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===== كرت تاكسي + زر فتح الرابط =====

class _TaxiCard extends StatelessWidget {
  final bool isArabic;

  final String titleAr;

  final String titleEn;

  final String descriptionAr;

  final String descriptionEn;

  final String link;

  const _TaxiCard({
    required this.isArabic,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.link,
  });

  IconData _detectIcon() {
    if (link.startsWith('tel:')) return Icons.phone;

    if (link.contains('play.google.com')) return Icons.android;

    if (link.contains('apple.com')) return Icons.phone_iphone;

    return Icons.language;
  }

  Future<void> _openLink() async {
    final uri = Uri.parse(link);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isArabic ? titleAr : titleEn;

    final desc = isArabic ? descriptionAr : descriptionEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: Icon(Icons.local_taxi, size: 30, color: Colors.black87),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          desc,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: Icon(_detectIcon(), color: Colors.blue),
          onPressed: _openLink,
        ),
      ),
    );
  }
}
