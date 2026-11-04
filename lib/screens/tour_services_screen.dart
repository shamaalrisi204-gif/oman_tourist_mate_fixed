import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../models/trip_tour_item.dart';

import 'map_gmaps_screen.dart' show kTripPlans;

import 'your_trip_screen.dart';

class TourServicesScreen extends StatefulWidget {
  final bool isArabic;

  final bool isGuest;

  const TourServicesScreen({
    super.key,
    required this.isArabic,
    this.isGuest = false,
  });

  @override
  State<TourServicesScreen> createState() => _TourServicesScreenState();
}

class _TourServicesScreenState extends State<TourServicesScreen> {
  String selectedCategory = 'all';

  final categories = {
    'all': {'ar': 'كل الأنواع', 'en': 'All types'},
    'adventure': {'ar': 'المغامرة', 'en': 'Adventure'},
    'nature': {'ar': 'الطبيعة والحياة الفطرية', 'en': 'Nature & Wildlife'},
    'sport': {'ar': 'الرياضة', 'en': 'Sport'},
    'culture': {'ar': 'الثقافة والتراث', 'en': 'Culture & Heritage'},
  };

  List<TripTourItem> get filteredTours {
    if (selectedCategory == 'all') return kToursList;

    return kToursList.where((t) => t.categoryKey == selectedCategory).toList();
  }

  void _showGuestDialog() {
    final isAr = widget.isArabic;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAr ? 'تسجيل الدخول مطلوب' : 'Login required',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        content: Text(
          isAr
              ? 'لإضافة الرحلات إلى رحلتك أو المفضلة أو فتح الروابط، الرجاء تسجيل الدخول أو إنشاء حساب جديد.'
              : 'To add tours to your trip or favorites, or open links, please sign in or create an account.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);

              Navigator.pushNamed(context, '/login');
            },
            child: Text(
              isAr ? 'تسجيل الدخول' : 'Sign in',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);

              Navigator.pushNamed(context, '/signup');
            },
            child: Text(
              isAr ? 'إنشاء حساب' : 'Create account',
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = widget.isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr ? 'الرحلات السياحية' : 'Tours',
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHero(
            isAr
                ? 'استكشفي أجمل الرحلات في عُمان'
                : 'Discover amazing tours in Oman',
            isAr
                ? 'اختاري نوع الرحلة التي تناسبك واحجزي بسهولة عبر Visit Oman.'
                : 'Choose the tour that fits you and book easily via Visit Oman.',
          ),
          const SizedBox(height: 20),
          Text(
            isAr ? 'الفلترة حسب النوع:' : 'Filter by type:',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: categories.entries.map((c) {
              return DropdownMenuItem(
                value: c.key,
                child: Text(isAr ? c.value['ar']! : c.value['en']!),
              );
            }).toList(),
            onChanged: (val) => setState(() => selectedCategory = val!),
          ),
          const SizedBox(height: 20),
          Text(
            isAr ? 'أفضل الرحلات' : 'Top tours',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ...filteredTours.map(_tourCard).toList(),
        ],
      ),
    );
  }

  Widget _buildHero(String title, String sub) {
    return SizedBox(
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/tours/hero_tours.jpg',
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
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
          ),
        ],
      ),
    );
  }

  Widget _tourCard(TripTourItem t) {
    final isAr = widget.isArabic;

    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة

          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Image.asset(
              t.imgAsset,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAr ? t.nameAr : t.nameEn,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAr ? t.shortAr : t.shortEn,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isAr
                      ? 'الموقع: ${t.locationAr}'
                      : 'Location: ${t.locationEn}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        t.isFav ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        if (widget.isGuest) {
                          _showGuestDialog();

                          return;
                        }

                        setState(() => t.isFav = !t.isFav);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? (t.isFav
                                      ? 'أضيفت إلى المفضلة'
                                      : 'تمت الإزالة من المفضلة')
                                  : (t.isFav
                                      ? 'Added to favorites'
                                      : 'Removed from favorites'),
                              style: const TextStyle(fontFamily: 'Tajawal'),
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.blue),
                      onPressed: () {
                        if (widget.isGuest) {
                          _showGuestDialog();

                          return;
                        }

                        _openUrl(t.infoUrl);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.airplane_ticket_outlined),
                      onPressed: () {
                        if (widget.isGuest) {
                          _showGuestDialog();

                          return;
                        }

                        _openUrl(t.bookingUrl);
                      },
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        isAr ? 'أضف لرحلتي' : 'Add to trip',
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                      onPressed: () {
                        if (widget.isGuest) {
                          _showGuestDialog();

                          return;
                        }

                        final exists = kTripTours.any((x) => x.id == t.id);

                        if (!exists) {
                          kTripTours.add(t);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تمت إضافة الرحلة إلى رحلتك ✈️'
                                  : 'Tour added to your trip ✈️',
                              style: const TextStyle(fontFamily: 'Tajawal'),
                            ),
                          ),
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => YourTripScreen(plans: kTripPlans),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر فتح الرابط حالياً',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      );
    }
  }
}
