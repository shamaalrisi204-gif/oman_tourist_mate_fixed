import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/prefs.dart';
import '../core/app_state.dart';
import '../screens/map_gmaps_screen.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

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

class _UserHomeState extends State<UserHome> {
  Map<String, dynamic>? _userData;
  bool _isArabic = true;

  // ---------- إعدادات السلايدر + الفيديو ----------
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoTimer;
  VideoPlayerController? _videoController;

  // ---------- ألوان ثابتة للثيم ----------
  static const Color _primary = Color(0xFF5E2BFF); // لو احتجناه لاحقاً
  static const Color _background = Color(0xFFF3EED9); // خلفية الصفحة
  static const Color _cardBeige = Color(0xFFE5D7B8); // كروت الأزرار
  static const Color _buttonBeige = Color(0xFFD6C39A); // زر تعديل التفضيلات

  // ---------- تعريف السلايدات ----------
  late final List<_HeroSlide> _slides = [
    _HeroSlide(
      asset: 'assets/hero/whales.jpg',
      isVideo: false,
      titleAr: 'لحظات لا تُنسى في سواحل عُمان',
      titleEn: 'Unforgettable moments on Oman’s coast',
      subtitleAr: 'اكتشف البحر والحياة البحرية في أجواء هادئة.',
      subtitleEn: 'Discover the sea and marine life in peaceful vibes.',
    ),
    _HeroSlide(
      asset: 'assets/hero/mountains.mp4',
      isVideo: true,
      titleAr: 'مغامرات بين الجبال والوديان',
      titleEn: 'Adventures among mountains & valleys',
      subtitleAr: 'شاهد الطبيعة العمانية من زوايا جديدة.',
      subtitleEn: 'See Oman’s nature from new perspectives.',
    ),
    _HeroSlide(
      asset: 'assets/hero/girl.jpg',
      isVideo: false,
      titleAr: 'روح الضيافة العمانية',
      titleEn: 'The spirit of Omani hospitality',
      subtitleAr: 'ابتسامة واحدة تكفي لتشعري وكأنك في بيتك.',
      subtitleEn: 'One smile is enough to feel at home.',
    ),
    _HeroSlide(
      asset: 'assets/hero/tower.jpg',
      isVideo: false,
      titleAr: 'تاريخ وحضارة عبر القرون',
      titleEn: 'History & heritage through the ages',
      subtitleAr: 'استكشفي قلاع عُمان وأسواقها القديمة.',
      subtitleEn: 'Explore Oman’s forts and old souqs.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadLanguage();
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
    // نبحث عن أول سلايد من نوع فيديو
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
        'interests': sp.getStringList('user_interests') ?? [],
      };
    });
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
    if (_userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final interests = (_userData!['interests'] as List).join(', ');

    final title = _isArabic ? 'الصفحة الرئيسية' : 'Home Page';
    final welcome = _isArabic
        ? 'مرحبًا بك في ${_userData!['city']}'
        : 'Welcome to ${_userData!['city']}';
    final mapBtn = _isArabic ? 'خريطة عمان' : 'Oman Map';
    final planBtn =
        _isArabic ? 'رحلة ممتعة تبدأ من هنا ✨' : 'Your journey starts here ✨';
    final favBtn = _isArabic ? 'المفضلة' : 'Favorites';
    final aboutBtn = _isArabic ? 'عن التطبيق' : 'About Us';
    final contactBtn = _isArabic ? 'تواصل معنا' : 'Contact Us';
    final langBtn = _isArabic ? 'English' : 'العربية';

    final coords =
        '📍 ${_userData!['city']} – ${_userData!['lat']}, ${_userData!['lng']}';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'about') {
                Navigator.pushNamed(context, '/about');
              } else if (value == 'contact') {
                Navigator.pushNamed(context, '/contact');
              } else if (value == 'lang') {
                _toggleLanguage();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'about', child: Text(aboutBtn)),
              PopupMenuItem(value: 'contact', child: Text(contactBtn)),
              PopupMenuItem(value: 'lang', child: Text(langBtn)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          // ====== السلايدر مع الكتابة فوق الصور / الفيديو ======
          _buildHeroSlider(),

          const SizedBox(height: 16),
          Text(
            welcome,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                ),
          ),
          const SizedBox(height: 16),

          // زر خريطة عمان
          _cardItem(
            icon: Icons.map,
            title: mapBtn,
            subtitle: _isArabic
                ? 'استكشف المواقع والمعالم السياحية في عمان'
                : 'Explore Oman’s famous landmarks',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OmanGMapsScreen(),
                ),
              );
            },
          ),

          // زر رحلة ممتعة
          _cardItem(
            icon: Icons.tour,
            title: planBtn,
            subtitle: _isArabic
                ? 'مساعدك الذكي لاقتراح الخطط السياحية'
                : 'Your AI trip planner',
            onTap: () => Navigator.pushNamed(context, '/ai_chat'),
          ),

          // زر المفضلة
          _cardItem(
            icon: Icons.favorite,
            title: favBtn,
            subtitle:
                _isArabic ? 'الأماكن التي قمت بحفظها' : 'Your saved places',
            onTap: () => Navigator.pushNamed(context, '/favorites'),
          ),

          const SizedBox(height: 16),
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
            _isArabic ? 'اهتماماتك:' : 'Your interests:',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: 'Tajawal',
                ),
          ),
          Text(
            interests.isEmpty ? '—' : interests,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),

          const SizedBox(height: 20),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _buttonBeige, // بيج أغمق من الكروت
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () => Navigator.pushNamed(context, '/preferences'),
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
                if (slide.isVideo &&
                    _videoController != null &&
                    _videoController!.value.isInitialized) {
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
                    // صورة / فيديو
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

                    // تدرّج غامق بسيط عشان القراءة
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

                    // النص فوق الصورة/الفيديو
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

          // زر السابق
          Positioned(
            left: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black45,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: () {
                  int prev = _currentPage - 1;
                  if (prev < 0) prev = _slides.length - 1;
                  _pageController.animateToPage(
                    prev,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),

          // زر التالي
          Positioned(
            right: 8,
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.black45,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: () {
                  int next = _currentPage + 1;
                  if (next >= _slides.length) next = 0;
                  _pageController.animateToPage(
                    next,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ),
          ),

          // نقاط المؤشر
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

  // ================= Card Item =================
  Widget _cardItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: _cardBeige,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black87, size: 30),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Colors.black87,
            fontFamily: 'Tajawal',
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.black87,
        ),
        onTap: onTap,
      ),
    );
  }
}
