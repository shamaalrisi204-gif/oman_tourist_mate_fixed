// lib/screens/attractions_screen.dart

import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import '../core/prefs.dart';

import '../models/trip_attraction_item.dart';

import '../screens/your_trip_screen.dart';

import 'map_gmaps_screen.dart' show kTripPlans;

class AttractionsScreen extends StatefulWidget {
  final bool isArabic;

  final bool isGuest; // 👈 جديد

  const AttractionsScreen({
    super.key,
    required this.isArabic,
    this.isGuest = false,
  });

  @override
  State<AttractionsScreen> createState() => _AttractionsScreenState();
}

class _AttractionsScreenState extends State<AttractionsScreen> {
  String selectedCity = 'all';

  String? _userCity;

  double? _lat;

  double? _lng;

  List<String> _userInterests = [];

  final cities = {
    'all': {'ar': 'كل المناطق', 'en': 'All Regions'},
    'Muscat': {'ar': 'مسقط', 'en': 'Muscat'},
    'Dhofar': {'ar': 'ظفار', 'en': 'Dhofar'},
    'Dakhiliyah': {'ar': 'الداخلية', 'en': 'Ad Dakhiliyah'},
  };

  static const Map<String, Map<String, String>> _interestNames = {
    'shopping': {'ar': 'تسوّق', 'en': 'Shopping'},
    'heritage': {'ar': 'أماكن تراثية وتاريخية', 'en': 'Heritage & history'},
    'nature': {'ar': 'مواقع طبيعية', 'en': 'Nature spots'},
    'beach': {'ar': 'شواطئ', 'en': 'Beaches'},
    'adventure': {'ar': 'مغامرات', 'en': 'Adventures'},
    'food': {'ar': 'مقاهي ومطاعم', 'en': 'Cafés & restaurants'},
  };

  List<TripAttractionItem> get filteredAttractions {
    if (selectedCity == 'all') return kAttractionsList;

    return kAttractionsList.where((a) => a.cityKey == selectedCity).toList();
  }

  @override
  void initState() {
    super.initState();

    _loadUserSummary();
  }

  Future<void> _loadUserSummary() async {
    final sp = await Prefs.raw;

    setState(() {
      _userCity = sp.getString('user_city') ?? 'مسقط';

      _lat = sp.getDouble('user_lat');

      _lng = sp.getDouble('user_lng');

      _userInterests = sp.getStringList('user_interests') ?? <String>[];
    });
  }

  String _buildInterestsText(bool isAr) {
    if (_userInterests.isEmpty) {
      return isAr
          ? 'لم تختاري اهتمامات بعد'
          : 'No favorite interests selected yet';
    }

    final labels = _userInterests.map((id) {
      final names = _interestNames[id];

      if (names == null) return isAr ? 'غير معروف' : 'Unknown';

      return isAr ? names['ar']! : names['en']!;
    }).toList();

    return isAr ? labels.join('، ') : labels.join(', ');
  }

  // 🔒 دايلوج للضيف

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
              ? 'لحفظ المعالم في المفضلة أو إضافتها إلى رحلتك أو فتح الروابط، الرجاء تسجيل الدخول أو إنشاء حساب جديد.'
              : 'To add attractions to favorites / trip or open links, please sign in or create an account.',
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

    final savedCity = _userCity ?? (isAr ? 'مسقط' : 'Muscat');

    final interestsText = _buildInterestsText(isAr);

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isAr ? 'المعالم السياحية' : 'Attractions',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeroHeader(isAr),

            const SizedBox(height: 16),

            // بطاقة معلومات المستخدم

            _buildUserSummaryCard(
              isAr: isAr,
              city: savedCity,
              interestsText: interestsText,
            ),

            const SizedBox(height: 20),

            // الفلترة

            Text(
              isAr ? 'الفلترة حسب المنطقة:' : 'Filter by region:',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedCity,
              items: cities.entries.map((c) {
                return DropdownMenuItem(
                  value: c.key,
                  child: Text(isAr ? c.value['ar']! : c.value['en']!),
                );
              }).toList(),
              onChanged: (val) => setState(() => selectedCity = val!),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isAr ? 'أفضل المعالم لرحلتك' : 'Top attractions',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            ...filteredAttractions.map(_buildAttractionCard),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ----------------- HERO HEADER -----------------

  Widget _buildHeroHeader(bool isAr) {
    return SizedBox(
      height: 210,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              'assets/attractions/hero.jpg',
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
                    isAr ? 'المعالم السياحية' : 'Local Attractions',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAr
                        ? 'استمتعي بزيارة المتاحف، القلاع، والأسواق التقليدية في سلطنة عُمان.'
                        : 'Enjoy museums, forts and traditional souqs across Oman.',
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

  // ----------------- USER SUMMARY CARD -----------------

  Widget _buildUserSummaryCard({
    required bool isAr,
    required String city,
    required String interestsText,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EED9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment:
            isAr ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            isAr ? 'معلومات من ملفك' : 'From your profile',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAr ? 'مدينتك المفضلة: $city' : 'Your saved city: $city',
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            isAr ? 'اهتماماتك:' : 'Your interests:',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            interestsText,
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ----------------- ATTRACTION CARD -----------------

  Widget _buildAttractionCard(TripAttractionItem item) {
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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(18),
            ),
            child: Image.asset(
              item.imgAsset,
              height: 180,
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
                  isAr ? item.nameAr : item.nameEn,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  isAr ? item.descAr : item.descEn,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    // ❤️ مفضلة

                    IconButton(
                      icon: Icon(
                        item.isFav ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        if (widget.isGuest) {
                          _showGuestDialog(); // 🔒

                          return;
                        }

                        setState(() => item.isFav = !item.isFav);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? (item.isFav
                                      ? 'تمت الإضافة إلى المفضلة'
                                      : 'تمت الإزالة من المفضلة')
                                  : (item.isFav
                                      ? 'Added to favorites'
                                      : 'Removed from favorites'),
                              style: const TextStyle(fontFamily: 'Tajawal'),
                            ),
                          ),
                        );
                      },
                    ),

                    // 🔗 المزيد

                    IconButton(
                      icon: const Icon(Icons.open_in_new, color: Colors.blue),
                      onPressed: () {
                        if (widget.isGuest) {
                          _showGuestDialog(); // 🔒
                        } else {
                          _openMore(item.moreUrl);
                        }
                      },
                    ),

                    const Spacer(),

                    // ➕ أضف إلى رحلتي

                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        isAr ? 'أضف إلى رحلتي' : 'Add to trip',
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                      onPressed: () {
                        if (widget.isGuest) {
                          _showGuestDialog(); // 🔒

                          return;
                        }

                        if (!kTripAttractions.contains(item)) {
                          kTripAttractions.add(item);
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isAr
                                  ? 'تمت إضافة المعلم إلى رحلتك'
                                  : 'Attraction added to your trip',
                              style: const TextStyle(fontFamily: 'Tajawal'),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // زر عرض "رحلتي"

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      if (widget.isGuest) {
                        _showGuestDialog(); // 🔒

                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => YourTripScreen(plans: kTripPlans),
                        ),
                      );
                    },
                    child: Text(
                      isAr ? 'عرض رحلتي' : 'View My Trip',
                      style: const TextStyle(fontFamily: 'Tajawal'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openMore(String url) async {
    final uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isArabic ? 'تعذّر فتح الرابط' : 'Could not open link',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      );
    }
  }
}
