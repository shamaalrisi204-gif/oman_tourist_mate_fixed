// lib/screens/flight_services_screen.dart

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

class FlightServicesScreen extends StatelessWidget {
  const FlightServicesScreen({
    super.key,
    required this.isArabic,
    required this.isGuest,
  });

  final bool isArabic;

  final bool isGuest;

  // دالة لو المستخدم Guest نطلّع له تنبيه بدال ما نفتح الرابط

  Future<void> _handleLinkTap(BuildContext context, String url) async {
    if (isGuest) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            isArabic ? 'تسجيل الدخول مطلوب' : 'Login required',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          content: Text(
            isArabic
                ? 'لحجز الرحلات أو استخدام الروابط الخارجية، يجب إنشاء حساب أو تسجيل الدخول أولاً.'
                : 'To book flights or open external links, please create an account or sign in first.',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);

                Navigator.pushNamed(context, '/login');
              },
              child: Text(
                isArabic ? 'تسجيل الدخول' : 'Sign In',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);

                Navigator.pushNamed(context, '/signup');
              },
              child: Text(
                isArabic ? 'إنشاء حساب' : 'Create account',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                isArabic ? 'إلغاء' : 'Cancel',
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
          ],
        ),
      );

      return;
    }

    // لو مو Guest نفتح الرابط عادي

    final uri = Uri.parse(url);

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final tTitle = isArabic ? 'رحلات الطيران' : 'Flights';

    final tHeroTitle =
        isArabic ? 'اكتشفي عُمان من السماء' : 'Discover Oman from the sky';

    final tHeroSub = isArabic
        ? 'احجزي رحلتك مباشرة من المواقع الرسمية لشركات الطيران أو استمتعي بالخدمات المقدمة في مطار مسقط.'
        : 'Book directly from official airline websites and enjoy Muscat airport services.';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tTitle,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHero(tHeroTitle, tHeroSub),

          const SizedBox(height: 20),

          // -------- Airlines --------

          _sectionTitle(
              isArabic ? 'شركاؤنا في الطيران' : 'Our Airline Partners'),

          const SizedBox(height: 8),

          SizedBox(
            height: 230,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _airlineCard(
                  context: context,
                  isArabic: isArabic,
                  nameAr: 'الطيران العُماني',
                  nameEn: 'Oman Air',
                  descriptionAr:
                      'الناقل الوطني مع شبكة واسعة من الوجهات حول العالم.',
                  descriptionEn:
                      'National carrier with a wide international route network.',
                  img: 'assets/airlines/oman_air.jpg',
                  url: 'https://www.omanair.com',
                ),
                _airlineCard(
                  context: context,
                  isArabic: isArabic,
                  nameAr: 'طيران السلام',
                  nameEn: 'Salam Air',
                  descriptionAr:
                      'شركة طيران منخفضة التكلفة تربط عُمان بعدة وجهات.',
                  descriptionEn:
                      'Low-cost carrier connecting Oman to many destinations.',
                  img: 'assets/airlines/salam_air.jpg',
                  url: 'https://www.salamair.com',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // -------- Airport services --------

          _sectionTitle(
              isArabic ? 'الخدمات في مطار مسقط' : 'Muscat Airport Services'),

          const SizedBox(height: 8),

          _serviceCard(
            context: context,
            isArabic: isArabic,
            titleAr: 'صالة المطار (Lounge)',
            titleEn: 'Airport Lounge Access',
            priceAr: 'الأسعار حسب نوع الصالة',
            priceEn: 'Prices vary by lounge type',
            descriptionAr: 'استمتعي بالراحة والهدوء قبل موعد الرحلة.',
            descriptionEn: 'Relax and refresh before your flight.',
            img: 'assets/airlines/lounge.jpg',
            url: 'https://muscatairport.co.om/en/page/services',
          ),

          _serviceCard(
            context: context,
            isArabic: isArabic,
            titleAr: 'خدمة الاستقبال والمساعدة',
            titleEn: 'Meet & Assist Service',
            priceAr: 'الأسعار حسب الباقة المختارة',
            priceEn: 'Prices vary per package',
            descriptionAr:
                'مساعدة في إجراءات السفر من لحظة الوصول حتى البوابة.',
            descriptionEn: 'Assistance from arrival until your boarding gate.',
            img: 'assets/airlines/meet_assist.jpg',
            url: 'https://muscatairport.co.om/en/page/services',
          ),

          _serviceCard(
            context: context,
            isArabic: isArabic,
            titleAr: 'تسجيل الوصول من المنزل',
            titleEn: 'Home Check-in Service',
            priceAr: 'قد تختلف حسب شركة الطيران',
            priceEn: 'May vary depending on airline',
            descriptionAr:
                'استلام الحقائب من المنزل وإنهاء إجراءات السفر مسبقاً.',
            descriptionEn:
                'Your bags are collected and check-in is completed from home.',
            img: 'assets/airlines/home_checkin.jpg',
            url: 'https://muscatairport.co.om/en/page/services',
          ),

          const SizedBox(height: 32),

          Text(
            isArabic
                ? 'يتم الحجز والدفع عبر المواقع الرسمية فقط. تطبيقك يساعد في الوصول للمعلومات بسهولة.'
                : 'Booking and payment are completed on official websites only.',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Widgets ----------------

  Widget _buildHero(String title, String sub) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/airlines/hero.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  static Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Tajawal',
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // -------- Airline card --------

  Widget _airlineCard({
    required BuildContext context,
    required bool isArabic,
    required String nameAr,
    required String nameEn,
    required String descriptionAr,
    required String descriptionEn,
    required String img,
    required String url,
  }) {
    final name = isArabic ? nameAr : nameEn;

    final desc = isArabic ? descriptionAr : descriptionEn;

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _handleLinkTap(context, url),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.asset(
                  img,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isArabic ? 'احجزي الآن' : 'Book now',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        color: Colors.teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------- Airport service card --------

  Widget _serviceCard({
    required BuildContext context,
    required bool isArabic,
    required String titleAr,
    required String titleEn,
    required String priceAr,
    required String priceEn,
    required String descriptionAr,
    required String descriptionEn,
    required String img,
    required String url,
  }) {
    final title = isArabic ? titleAr : titleEn;

    final price = isArabic ? priceAr : priceEn;

    final desc = isArabic ? descriptionAr : descriptionEn;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _handleLinkTap(context, url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.asset(
                img,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
