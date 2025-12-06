// lib/screens/user_home.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/prefs.dart';
import '../core/app_state.dart';
import 'map_gmaps_screen.dart'; // فيه kTripPlans
import '../screens/your_trip_screen.dart';
import 'flight_services_screen.dart';
import 'hotel_services_screen.dart';
import 'transport_services_screen.dart'; // شاشة النقل الجديدة
import 'dining_services_screen.dart';
import 'attractions_screen.dart';
import '../models/trip_hotel_item.dart' show kTripHotels;
import 'tour_services_screen.dart'; // شاشة الرحلات السياحية
import '../models/trip_tour_item.dart'
    show kTripTours; // قائمة التورز المضافة لرحلتي
import 'preference_screen.dart';

class UserHome extends StatefulWidget {
  const UserHome({
    super.key,
    this.isGuest = false,
  });

  final bool isGuest;

  @override
  State<UserHome> createState() => _UserHomeState();
}

/// موديل للسلايد (صورة أو فيديو + نص)
class _HeroSlide {
  final String asset;
  final bool isVideo;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;

  const _HeroSlide({
    required this.asset,
    required this.isVideo,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
  });
}

/// موديل للكروت السريعة (رحلات الطيران، الإقامة، ...)
class _CategoryItem {
  final IconData icon;
  final String titleAr;
  final String titleEn;

  const _CategoryItem({
    required this.icon,
    required this.titleAr,
    required this.titleEn,
  });
}

class _UserHomeState extends State<UserHome> {
  Map<String, dynamic>? _userData;

  bool _isArabic = true;
  String? _userName;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoTimer;
  VideoPlayerController? _videoController;

  static const Color _background = Color(0xFFF3EED9);
  static const Color _prefButtonColor = Color(0xFFE0CDA0);

  // أسماء الاهتمامات
  static const Map<String, Map<String, String>> _interestNames = {
    'shopping': {'ar': 'تسوّق', 'en': 'Shopping'},
    'heritage': {'ar': 'أماكن تراثية وتاريخية', 'en': 'Heritage & history'},
    'nature': {'ar': 'مواقع طبيعية', 'en': 'Nature spots'},
    'beach': {'ar': 'شواطئ', 'en': 'Beaches'},
    'adventure': {'ar': 'مغامرات', 'en': 'Adventures'},
    'food': {'ar': 'مقاهي ومطاعم', 'en': 'Cafés & restaurants'},
  };

  // السلايدات
  late final List<_HeroSlide> _slides = [
    const _HeroSlide(
      asset: 'assets/hero/whales.jpg',
      isVideo: false,
      titleAr: 'لحظات لا تُنسى في سواحل عُمان',
      titleEn: 'Unforgettable moments on Oman’s coast',
      subtitleAr: 'اكتشفي البحر والحياة البحرية في أجواء هادئة.',
      subtitleEn: 'Discover the sea and marine life in peaceful vibes.',
    ),
    const _HeroSlide(
      asset: 'assets/hero/mountains.mp4',
      isVideo: true,
      titleAr: 'مغامرات بين الجبال والوديان',
      titleEn: 'Adventures among mountains & valleys',
      subtitleAr: 'شاهدي الطبيعة العُمانية من زوايا جديدة.',
      subtitleEn: 'See Oman’s nature from new perspectives.',
    ),
    const _HeroSlide(
      asset: 'assets/hero/girl.jpg',
      isVideo: false,
      titleAr: 'روح الضيافة العُمانية',
      titleEn: 'The spirit of Omani hospitality',
      subtitleAr: 'ابتسامة واحدة تكفي لتشعري وكأنك في بيتك.',
      subtitleEn: 'One smile is enough to feel at home.',
    ),
    const _HeroSlide(
      asset: 'assets/hero/tower.jpg',
      isVideo: false,
      titleAr: 'تاريخ وحضارة عبر القرون',
      titleEn: 'History & heritage through the ages',
      subtitleAr: 'استكشفي قلاع عُمان وأسواقها القديمة.',
      subtitleEn: 'Explore Oman’s forts and old souqs.',
    ),
  ];

  // الكروت السريعة مثل Visit Qatar (Flights, Stays, ...)
  static const List<_CategoryItem> _categories = [
    _CategoryItem(
      icon: Icons.flight_takeoff,
      titleAr: 'رحلات الطيران',
      titleEn: 'Flights',
    ),
    _CategoryItem(
      icon: Icons.hotel,
      titleAr: 'أماكن الإقامة',
      titleEn: 'Stays',
    ),
    _CategoryItem(
      icon: Icons.tour,
      titleAr: 'الرحلات السياحية',
      titleEn: 'Tours',
    ),
    _CategoryItem(
      icon: Icons.attractions,
      titleAr: 'المعالم السياحية',
      titleEn: 'Attractions',
    ),
    _CategoryItem(
      icon: Icons.directions_bus,
      titleAr: 'النقل',
      titleEn: 'Transport',
    ),
    _CategoryItem(
      icon: Icons.restaurant,
      titleAr: 'الطعام',
      titleEn: 'Food & Dining',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadLanguage();
    _loadUserName();
    _initVideoController();
    _startAutoSlide();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideoController() async {
    final videoSlide =
        _slides.firstWhere((s) => s.isVideo, orElse: () => _slides[0]);
    if (!videoSlide.isVideo) return;

    _videoController = VideoPlayerController.asset(videoSlide.asset);
    await _videoController!.initialize();
    _videoController!
      ..setLooping(true)
      ..setVolume(0.0);

    if (mounted) setState(() {});
  }

  void _startAutoSlide() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _slides.isEmpty) return;
      int next = _currentPage + 1;
      if (next >= _slides.length) next = 0;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _loadSummary() async {
    final sp = await Prefs.raw;
    setState(() {
      _userData = {
        'city': sp.getString('user_city') ?? 'مسقط',
        'lat': sp.getDouble('user_lat') ?? 23.5880,
        'lng': sp.getDouble('user_lng') ?? 58.3829,
        'interests': sp.getStringList('user_interests') ?? <String>[],
      };
    });
  }

  Future<void> _loadLanguage() async {
    final ar = await Prefs.isArabic;
    if (!mounted) return;
    setState(() => _isArabic = ar);
  }

  Future<void> _loadUserName() async {
    final name = await Prefs.getUserName();
    if (!mounted) return;
    setState(() => _userName = name);
  }

  Future<void> _toggleLanguage() async {
    final app = AppStateProvider.of(context);
    final newCode = _isArabic ? 'en' : 'ar';
    await app.setLanguage(newCode);
    if (!mounted) return;
    setState(() => _isArabic = !_isArabic);
  }

  void _showGuestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          _isArabic ? 'تسجيل الدخول مطلوب' : 'Login Required',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          _isArabic
              ? 'هذه الميزة متاحة فقط للمستخدمين المسجلين.\nسجّل دخولك أو أنشئ حساباً جديداً للاستفادة من مساعد الرحلات والمفضلة.'
              : 'This feature is available only for registered users.\nPlease sign in or create a new account to use trip assistant and favorites.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
            child: Text(
              _isArabic ? 'تسجيل الدخول' : 'Sign In',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              _isArabic ? 'إلغاء' : 'Cancel',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildInterestsText() {
    final ids = List<String>.from(_userData!['interests'] as List);
    if (ids.isEmpty) {
      return _isArabic
          ? 'لم تختاري اهتمامات بعد'
          : 'No favorite interests selected yet';
    }
    final labels = ids.map((id) {
      final names = _interestNames[id];
      if (names == null) return _isArabic ? 'غير معروف' : 'Unknown';
      return _isArabic ? names['ar']! : names['en']!;
    }).toList();
    return _isArabic ? labels.join('، ') : labels.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final title = _isArabic ? 'الصفحة الرئيسية' : 'Home Page';

    final welcome = _isArabic ? 'مرحبًا بك في عُمان' : 'Welcome to Oman';

    final coords =
        '📍 ${_userData!['city']} – ${_userData!['lat']}, ${_userData!['lng']}';

    final interestsTitle =
        _isArabic ? 'اهتماماتك المفضلة:' : 'Your favorite interests:';

    final interestsText = _buildInterestsText();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 90,
        leading: TextButton(
          onPressed: _toggleLanguage,
          child: Text(
            _isArabic ? 'English' : 'العربية',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          // اسم المستخدم أو Guest

          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic ? 'مرحباً،' : 'Hello,',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 3),

                // إذا "مو" ضيف → نعرض الاسم
                if (!widget.isGuest &&
                    _userName != null &&
                    _userName!.isNotEmpty)
                  Text(
                    _userName!,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
          ),

          // السلايدر
          _buildHeroSlider(),
          const SizedBox(height: 16),

          Text(
            welcome,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
          ),

          const SizedBox(height: 12),

          // كرت Useful Info العريض
          _buildUsefulInfoCard(),
          const SizedBox(height: 16),

          // الكروت السريعة Flights / Stays / ...
          _buildQuickCategories(),
          const SizedBox(height: 16),

          // كرت My Trip العريض تحت الكروت
          _buildMyTripCard(),
          const SizedBox(height: 20),

          // معلومات الموقع والاهتمامات
          Text(
            _isArabic ? 'موقعك المحفوظ:' : 'Your saved location:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Tajawal',
                ),
          ),
          Text(
            coords,
            style: const TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
          ),
          const SizedBox(height: 8),
          Text(
            interestsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Tajawal',
                ),
          ),
          Text(
            interestsText,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _prefButtonColor,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreferencesScreen(
                      isGuest: widget.isGuest, // 👈 لو guest بيرجع كـ guest
                    ),
                  ),
                );
              },
              child: Text(
                _isArabic ? 'تعديل التفضيلات' : 'Edit Preferences',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ====== كرت Useful Info العريض في الهوم ======
  Widget _buildUsefulInfoCard() {
    final label = _isArabic ? 'معلومات قد تهمك' : 'Useful Info';

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/tips'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, color: Colors.black87, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== كرت My Trip العريض ======
  // ====== كرت My Trip العريض ======

  Widget _buildMyTripCard() {
    final label = _isArabic ? 'رحلتي' : 'My Trip';

    return InkWell(
      onTap: () {
        if (widget.isGuest) {
          _showGuestDialog();
        } else {
          // 🚀 افتح صفحة رحلاتي دايمًا

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YourTripScreen(plans: kTripPlans),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flag_outlined, color: Colors.black87, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= Bottom Navigation =================
  Widget _buildBottomNav(BuildContext context) {
    final isAr = _isArabic;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            break;
          case 1: // AI
            if (widget.isGuest) {
              _showGuestDialog();
            } else {
              Navigator.pushNamed(context, '/ai_chat');
            }
            break;
          case 2: // Favorites
            if (widget.isGuest) {
              _showGuestDialog();
            } else {
              Navigator.pushNamed(context, '/favorites');
            }
            break;
          case 3: // Map

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OmanGMapsScreen(
                  enablePlanning: !widget.isGuest, // الضيف: خريطة بدون تخطيط

                  guestMode: widget.isGuest, // نمرّر إنه ضيف أو لا

                  isArabic: _isArabic, // على حسب اللغة في UserHome
                ),
              ),
            );

            break;

          case 4: // Essentials (بدون Useful Info الآن)
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (_) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.group),
                        title: Text(
                          isAr ? 'نبذة عنا' : 'About Us',
                          style: const TextStyle(fontFamily: 'Tajawal'),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/about');
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.mail_outline),
                        title: Text(
                          isAr ? 'تواصل معنا' : 'Contact Us',
                          style: const TextStyle(fontFamily: 'Tajawal'),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/contact');
                        },
                      ),
                      const Divider(height: 0),
                      ListTile(
                        leading: const Icon(Icons.currency_exchange),
                        title: Text(
                          isAr ? 'محوّل العملات' : 'Currency Converter',
                          style: const TextStyle(fontFamily: 'Tajawal'),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/currency');
                        },
                      ),
                    ],
                  ),
                );
              },
            );
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          label: isAr ? 'الرئيسية' : 'Home',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.auto_awesome),
          label: isAr ? 'المساعد الذكي' : 'AI',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.favorite_border),
          label: isAr ? 'المفضلة' : 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.map_outlined),
          label: isAr ? 'الخريطة' : 'Map',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.grid_view),
          label: isAr ? 'الخدمات' : 'Essentials',
        ),
      ],
    );
  }

  // ================= Hero Slider =================
  Widget _buildHeroSlider() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
                _startAutoSlide();
                final slide = _slides[index];
                if (slide.isVideo && _videoController != null) {
                  _videoController!.play();
                } else {
                  _videoController?.pause();
                }
              },
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (slide.isVideo && _videoController != null)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      )
                    else
                      Image.asset(
                        slide.asset,
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
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isArabic ? slide.titleAr : slide.titleEn,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isArabic ? slide.subtitleAr : slide.subtitleEn,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            bottom: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_slides.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color:
                        active ? Colors.white : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ الكروت السريعة (Flights / Stays / Tours / ...)
  // ✅ الكروت السريعة (Flights / Stays / Tours / ...)

  Widget _buildQuickCategories() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.2,
      children: _categories.map((cat) {
        final label = _isArabic ? cat.titleAr : cat.titleEn;

        return InkWell(
          onTap: () {
            // ✈️ Flights

            // ✈️ Flights

            if (cat.titleEn == 'Flights') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FlightServicesScreen(
                    isArabic: _isArabic,
                    isGuest: widget.isGuest,
                  ),
                ),
              );

              return;
            }

            // 🏨 Stays

            if (cat.titleEn == 'Stays') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HotelServicesScreen(
                    isArabic: _isArabic,
                    isGuest: widget.isGuest,
                  ),
                ),
              );

              return;
            }

            // 🚌 Tours

            // 🚌 Tours

            if (cat.titleEn == 'Tours') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TourServicesScreen(
                    isArabic: _isArabic,

                    isGuest: widget.isGuest, // 👈 مهم
                  ),
                ),
              );

              return;
            }

            // ⭐ Attractions

            // 🏰 Attractions

            if (cat.titleEn == 'Attractions') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttractionsScreen(
                    isArabic: _isArabic,

                    isGuest: widget.isGuest, // 👈 مهم
                  ),
                ),
              );

              return;
            }

            // 🚕 Transport  👈新增 هني

            // 🚌 Transport

            if (cat.titleEn == 'Transport') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransportServicesScreen(
                    isArabic: _isArabic,

                    isGuest: widget.isGuest, // 👈 مهم عشان نعرف إنه ضيف
                  ),
                ),
              );

              return;
            }

            // 🍽️ Food & Dining

            // مثال داخل onTap في UserHome

            if (cat.titleEn == 'Food & Dining') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiningServicesScreen(
                    isArabic: _isArabic,

                    isGuest: widget.isGuest, // 👈 مهم
                  ),
                ),
              );

              return;
            }

            // باقي الخدمات = قريباً

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isArabic ? 'قريباً: $label' : 'Coming soon: $label',
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(cat.icon, size: 26, color: Colors.black87),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
