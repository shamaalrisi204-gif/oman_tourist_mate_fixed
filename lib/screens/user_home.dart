import 'package:flutter/material.dart';
import '../core/prefs.dart';
import '../core/app_state.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});
  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  Map<String, dynamic>? _userData;
  bool _isArabic = true;
  @override
  void initState() {
    super.initState();
    _loadSummary();
    _loadLanguage();
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
    final govMapBtn = _isArabic ? 'خريطة المحافظات' : 'Governorates Map';
    final planBtn =
        _isArabic ? 'رحلة ممتعة تبدأ من هنا ✨' : 'Your journey starts here ✨';
    final favBtn = _isArabic ? 'المفضلة' : 'Favorites';
    final aboutBtn = _isArabic ? 'عن التطبيق' : 'About Us';
    final contactBtn = _isArabic ? 'تواصل معنا' : 'Contact Us';
    final langBtn = _isArabic ? 'English' : 'العربية';
    final coords =
        '📍 ${_userData!['city']} – ${_userData!['lat']}, ${_userData!['lng']}';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            welcome,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _cardItem(
            icon: Icons.map,
            title: mapBtn,
            subtitle: _isArabic
                ? 'استكشف المواقع والمعالم السياحية في عمان'
                : 'Explore Oman’s famous landmarks',
            onTap: () => Navigator.pushNamed(context, '/map'),
          ),
          // ✅ زر جديد: خريطة المحافظات
          _cardItem(
            icon: Icons.public,
            title: govMapBtn,
            subtitle: _isArabic
                ? 'تعرّف على محافظات سلطنة عمان والمواقع السياحية بكل محافظة'
                : 'Explore Oman’s governorates and attractions',
            onTap: () => Navigator.pushNamed(context, '/gov_map'),
          ),
          _cardItem(
            icon: Icons.tour,
            title: planBtn,
            subtitle: _isArabic
                ? 'مساعدك الذكي لاقتراح الخطط السياحية'
                : 'Your AI trip planner',
            onTap: () => Navigator.pushNamed(context, '/ai_chat'),
          ),
          _cardItem(
            icon: Icons.favorite,
            title: favBtn,
            subtitle:
                _isArabic ? 'الأماكن التي قمت بحفظها' : 'Your saved places',
            onTap: () => Navigator.pushNamed(context, '/favorites'),
          ),
          _cardItem(
            icon: Icons.map_outlined,
            title: _isArabic
                ? 'خريطة المحافظات (تفاعلية)'
                : 'Governorates Map (Leaflet)',
            subtitle: _isArabic
                ? 'إضغط على المحافظة لعرض الأماكن السياحية'
                : 'Tap a governorate to see places',
            onTap: () => Navigator.pushNamed(context, '/gov_map'),
          ),

          const SizedBox(height: 16),
          Text(
            _isArabic ? 'موقعك المحفوظ:' : 'Your saved location:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(coords, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            _isArabic ? 'اهتماماتك:' : 'Your interests:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(interests.isEmpty ? '—' : interests),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.pushNamed(context, '/preferences'),
            child: Text(_isArabic ? 'تعديل التفضيلات' : 'Edit Preferences'),
          ),
        ],
      ),
    );
  }

  Widget _cardItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent, size: 30),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
