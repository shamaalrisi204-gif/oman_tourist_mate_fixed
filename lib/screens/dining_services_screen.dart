// lib/screens/dining_services_screen.dart

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

class DiningServicesScreen extends StatelessWidget {
  final bool isArabic;

  const DiningServicesScreen({super.key, required this.isArabic});

  static const Color _background = Color(0xFFF3EED9);

  @override
  Widget build(BuildContext context) {
    final title = isArabic ? 'الطعام' : 'Dining';

    final introTitle =
        isArabic ? 'مأكولات جديرة بالتجربة' : 'A Worthy Dining Experience';

    final introBody = isArabic
        ? '''عُمان هي أرض الأحلام لعشّاق الطعام وذوّاقة المأكولات، 

حيث أمام الزائر مجموعة متنوعة من خيارات تناول الطعام؛ 

بدءاً من المطاعم الفاخرة إلى الأكلات الشعبية العمانية الأصيلة.'''
        : '''Oman is a wonderful place for food lovers, 

offering a wide range of dining options from luxury restaurants 

to traditional Omani dishes.''';

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
          _buildHeroSection(introTitle, introBody),
          const SizedBox(height: 20),
          _buildCategorySection(context),
          const SizedBox(height: 25),
          _buildAlaqrRestaurant(context),
        ],
      ),
    );
  }

  // ------------------- هيرو كبير -------------------

  Widget _buildHeroSection(String title, String body) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/dining/hero.jpg',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
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
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
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
    );
  }

  // ------------------- الأقسام الثلاثة -------------------

  Widget _buildCategorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isArabic ? 'أنواع التجارب الغذائية' : 'Food Experiences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 14),

        // Grid of 3 cards

        GridView.count(
          crossAxisCount: 1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          children: [
            _CategoryCard(
              title: isArabic ? 'المطاعم الفاخرة' : 'Luxury Dining',
              image: 'assets/dining/luxury.jpg',
            ),
            _CategoryCard(
              title: isArabic ? 'نكهات عالمية' : 'Global Flavors',
              image: 'assets/dining/global.jpg',
            ),
            _CategoryCard(
              title: isArabic
                  ? 'الأطباق العمانية التقليدية'
                  : 'Traditional Omani Dishes',
              image: 'assets/dining/oman_food.jpg',
            ),
          ],
        ),
      ],
    );
  }

  // ------------------- مطعم العقَر -------------------

  Widget _buildAlaqrRestaurant(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          isArabic ? 'مطاعم شعبية' : 'Local Traditional Restaurants',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 14),
        _RestaurantCard(
          isArabic: isArabic,
          titleAr: 'مطعم العقر',
          titleEn: 'Alaqur Restaurant',
          descAr:
              'واحد من أشهر المطاعم التي تقدم الأكلات الشعبية العمانية الأصيلة، مع فرعين في نزوى وصلالة.',
          descEn:
              'One of the most popular Omani traditional restaurants with branches in Nizwa and Salalah.',
          image: 'assets/dining/alaqr.jpg',
          branches: [
            RestaurantBranch(
              nameAr: 'فرع نزوى',
              nameEn: 'Nizwa Branch',
              mapsUrl: 'https://maps.app.goo.gl/qQW9W8KSdM2gEwEJ9',
            ),
            RestaurantBranch(
              nameAr: 'فرع صلالة',
              nameEn: 'Salalah Branch',
              mapsUrl: 'https://maps.app.goo.gl/8zFa3X8h1Zp1z7bx5',
            ),
          ],
        ),
      ],
    );
  }
}

// --------------------------------------------------------

// Models + Cards

// --------------------------------------------------------

class RestaurantBranch {
  final String nameAr;

  final String nameEn;

  final String mapsUrl;

  RestaurantBranch({
    required this.nameAr,
    required this.nameEn,
    required this.mapsUrl,
  });
}

// ---------------- بطاقة القسم ----------------

class _CategoryCard extends StatelessWidget {
  final String title;

  final String image;

  const _CategoryCard({
    required this.title,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(image, fit: BoxFit.cover),
          Container(
            color: Colors.black.withOpacity(0.35),
          ),
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- بطاقة مطعم ----------------

class _RestaurantCard extends StatelessWidget {
  final bool isArabic;

  final String titleAr;

  final String titleEn;

  final String descAr;

  final String descEn;

  final String image;

  final List<RestaurantBranch> branches;

  const _RestaurantCard({
    required this.isArabic,
    required this.titleAr,
    required this.titleEn,
    required this.descAr,
    required this.descEn,
    required this.image,
    required this.branches,
  });

  @override
  Widget build(BuildContext context) {
    final title = isArabic ? titleAr : titleEn;

    final desc = isArabic ? descAr : descEn;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.asset(image,
                height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  desc,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // ----- الفروع -----

                ...branches.map((b) {
                  return Column(
                    children: [
                      ListTile(
                        leading:
                            const Icon(Icons.location_on, color: Colors.red),
                        title: Text(
                          isArabic ? b.nameAr : b.nameEn,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => launchUrl(Uri.parse(b.mapsUrl)),
                      ),
                      const Divider(height: 0),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
