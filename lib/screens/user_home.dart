import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/prefs.dart';
import '../core/app_state.dart';
import 'map_gmaps_screen.dart';
import '../screens/your_trip_screen.dart';
import 'flight_services_screen.dart';
import 'hotel_services_screen.dart';
import 'transport_services_screen.dart';
import 'dining_services_screen.dart';
import 'attractions_screen.dart';
import '../models/trip_hotel_item.dart' show kTripHotels;
import 'tour_services_screen.dart';
import '../models/trip_tour_item.dart' show kTripTours;
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

  static const Color _background = Color(0xFFF3FAFA);

  static const Color _prefButtonColor = Color(0xFFBCE5E3);

  static const Color _omaniGreen = Color(0xFF075C65);

  static const Color _softGold = Color(0xFFD8ECEA);

  static const Color _gold = Color(0xFF1B9AA3);

  static const Color _cream = Color(0xFFFFFFFF);

  static const Map<String, Map<String, String>> _interestNames = {
    'shopping': {'ar': 'تسوّق', 'en': 'Shopping'},
    'heritage': {'ar': 'أماكن تراثية وتاريخية', 'en': 'Heritage & history'},
    'nature': {'ar': 'مواقع طبيعية', 'en': 'Nature spots'},
    'beach': {'ar': 'شواطئ', 'en': 'Beaches'},
    'adventure': {'ar': 'مغامرات', 'en': 'Adventures'},
    'food': {'ar': 'مقاهي ومطاعم', 'en': 'Cafés & restaurants'},
  };

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
        toolbarHeight: 75,
        leadingWidth: 90,
        // زر تغيير اللغة
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
        // عنوان الصفحة والزخرفة الذهبية
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _omaniGreen,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 3),
            Image.asset(
              'assets/images/home/gold_ornament.png',
              width: 150,
              height: 25,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // الخلفية العُمانية
          Positioned.fill(
            child: Image.asset(
              'assets/images/home/home_background 1.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          // محتويات الصفحة مع التمرير
          ListView(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            children: [
              // صورة القلعة العُمانية
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: SizedBox(
                  height: 135,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/home/omani_header 1.png',
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                      Positioned(
                        top: 25,
                        left: 18,
                        right: 18,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isArabic ? 'مرحباً،' : 'Hello,',
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF5D5142),
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (!widget.isGuest &&
                                  _userName != null &&
                                  _userName!.isNotEmpty)
                                Text(
                                  _userName!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF263E35),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // السلايدر السياحي بإطار ذهبي

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFFD4A64F),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B7044).withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildHeroSlider(),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Container(
                        height: 1.5,
                        color: const Color(0xFFD4A64F),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 4,
                      child: Text(
                        _isArabic ? 'مرحبًا بك' : 'Welcome',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF123F35),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Image.asset(
                      'assets/images/home/omani_swords.png',
                      width: 48,
                      height: 58,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      flex: 3,
                      child: Text(
                        _isArabic ? 'في عُمان' : 'to Oman',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF123F35),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1.5,
                        color: const Color(0xFFD4A64F),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              _buildUsefulInfoCard(),

              const SizedBox(height: 16),
              _buildQuickCategories(),

              const SizedBox(height: 16),
              _buildMyTripCard(),

              const SizedBox(height: 20),

              Text(
                _isArabic ? 'موقعك المحفوظ:' : 'Your saved location:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'Tajawal',
                    ),
              ),

              Text(
                coords,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Tajawal',
                ),
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
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF4E9D8),
                    foregroundColor: const Color(0xFF123F35),
                    elevation: 0,
                    side: const BorderSide(
                      color: Color(0xFFD9BA7A),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PreferencesScreen(
                          isGuest: widget.isGuest,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.tune_rounded,
                    size: 23,
                    color: Color(0xFF123F35),
                  ),
                  label: Text(
                    _isArabic ? 'تعديل التفضيلات' : 'Edit Preferences',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123F35),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildUsefulInfoCard() {
    final label = _isArabic ? 'معلومات قد تهمك' : 'Useful Info';

    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/tips'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: 65,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFAF3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD9BA7A),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B7044).withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // الزخرفة العُمانية على يسار البطاقة

              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Opacity(
                  opacity: 0.65,
                  child: Image.asset(
                    'assets/images/home/omani_pattern 1.png',
                    width: 135,
                    height: 65,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),

              // النص وأيقونة المعلومات في الوسط

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF123F35),
                      size: 23,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Color(0xFF123F35),
                      ),
                    ),
                  ],
                ),
              ),

              // السهم على يمين البطاقة

              const Positioned(
                right: 12,
                child: Icon(
                  Icons.chevron_right,
                  color: Color(0xFFB68A42),
                  size: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyTripCard() {
    final label = _isArabic ? 'رحلتي' : 'My Trip';

    return InkWell(
      onTap: () {
        if (widget.isGuest) {
          _showGuestDialog();
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => YourTripScreen(plans: kTripPlans),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF174D40),
              Color(0xFF08362D),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFD9BA7A),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF123F35).withValues(alpha: 0.20),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // صورة الجبال الذهبية على اليسار

              Positioned(
                left: 0,
                bottom: 0,
                child: Image.asset(
                  'assets/images/home/oman_mountains.png',
                  width: 165,
                  height: 65,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomLeft,
                ),
              ),

              // كلمة رحلتي في منتصف الزر

              Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),

              // أيقونة العلم بجانب الكلمة

              Positioned(
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(53, 0),
                    child: const Icon(
                      Icons.flag_outlined,
                      color: Color(0xFFFFE5A8),
                      size: 27,
                    ),
                  ),
                ),
              ),

              // السهم على يمين الزر

              const Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Icon(
                  Icons.chevron_right,
                  color: Color(0xFFFFE5A8),
                  size: 25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final isAr = _isArabic;

    const navGreen = Color(0xFF123F35);

    const selectedBg = Color(0xFFEDE1CD);

    const gold = Color(0xFFC49A50);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF3),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: navGreen.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 0,
          backgroundColor: const Color(0xFFFFFAF3),
          selectedItemColor: navGreen,
          unselectedItemColor: navGreen,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          onTap: (index) {
            switch (index) {
              case 0:
                break;

              case 1:
                if (widget.isGuest) {
                  _showGuestDialog();
                } else {
                  Navigator.pushNamed(context, '/ai_chat');
                }

                break;

              case 2:
                if (widget.isGuest) {
                  _showGuestDialog();
                } else {
                  Navigator.pushNamed(context, '/favorites');
                }

                break;

              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OmanGMapsScreen(
                      enablePlanning: !widget.isGuest,
                      guestMode: widget.isGuest,
                      isArabic: _isArabic,
                    ),
                  ),
                );

                break;

              case 4:
                showModalBottomSheet(
                  context: context,
                  backgroundColor: const Color(0xFFFFFAF3),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (_) {
                    return SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.group,
                              color: navGreen,
                            ),
                            title: Text(
                              isAr ? 'نبذة عنا' : 'About Us',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);

                              Navigator.pushNamed(context, '/about');
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.mail_outline,
                              color: navGreen,
                            ),
                            title: Text(
                              isAr ? 'تواصل معنا' : 'Contact Us',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);

                              Navigator.pushNamed(context, '/contact');
                            },
                          ),
                          const Divider(height: 0),
                          ListTile(
                            leading: const Icon(
                              Icons.currency_exchange,
                              color: navGreen,
                            ),
                            title: Text(
                              isAr ? 'محوّل العملات' : 'Currency Converter',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                              ),
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
              icon: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selectedBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  size: 28,
                  color: navGreen,
                ),
              ),
              label: isAr ? 'الرئيسية' : 'Home',
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.auto_awesome,
                size: 26,
                color: gold,
              ),
              label: isAr ? 'المساعد الذكي' : 'AI Assistant',
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.favorite_border,
                size: 27,
              ),
              label: isAr ? 'المفضلة' : 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.map_outlined,
                size: 27,
              ),
              label: isAr ? 'الخريطة' : 'Map',
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.grid_view_rounded,
                size: 27,
              ),
              label: isAr ? 'الخدمات' : 'Services',
            ),
          ],
        ),
      ),
    );
  }

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
                    if (slide.isVideo &&
                        _videoController != null &&
                        _videoController!.value.isInitialized)
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
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.05),
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
                    color: active
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
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

  Widget _buildQuickCategories() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.7,
      children: _categories.map((cat) {
        final label = _isArabic ? cat.titleAr : cat.titleEn;

        return InkWell(
          onTap: () {
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

            if (cat.titleEn == 'Tours') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TourServicesScreen(
                    isArabic: _isArabic,
                    isGuest: widget.isGuest,
                  ),
                ),
              );
              return;
            }

            if (cat.titleEn == 'Attractions') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AttractionsScreen(
                    isArabic: _isArabic,
                    isGuest: widget.isGuest,
                  ),
                ),
              );
              return;
            }

            if (cat.titleEn == 'Transport') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TransportServicesScreen(
                    isArabic: _isArabic,
                    isGuest: widget.isGuest,
                  ),
                ),
              );
              return;
            }

            if (cat.titleEn == 'Food & Dining') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DiningServicesScreen(
                    isArabic: _isArabic,
                    isGuest: widget.isGuest,
                  ),
                ),
              );
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isArabic ? 'قريباً: $label' : 'Coming soon: $label',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFD9BA7A),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B7044).withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123F35),
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  cat.icon,
                  color: const Color(0xFF123F35),
                  size: 29,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
