// lib/screens/ai_concierge_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/ai_services.dart';
import '../data/tourism_repository.dart';
import '../models/ai_place_suggestion.dart';

class AiConciergeScreen extends StatefulWidget {
  const AiConciergeScreen({super.key});

  @override
  State<AiConciergeScreen> createState() => _AiConciergeScreenState();
}

class _AiConciergeScreenState extends State<AiConciergeScreen> {
  final _ai = AiService();
  final _repo = TourismRepository.I;

  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isArabic = true;
  bool _loading = false;

  String? _aiText;
  List<AiPlaceSuggestion> _results = [];

  /// نستخدم نفس المفتاح اللي في FavoritesScreen
  static const _favoritesKey = 'favorites_list_v1';
  final Set<String> _favoriteNames = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String t(String ar, String en) => _isArabic ? ar : en;

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_favoritesKey) ?? const [];
    setState(() {
      _favoriteNames
        ..clear()
        ..addAll(list);
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoritesKey, _favoriteNames.toList());
  }

  bool _isFavorite(AiPlaceSuggestion place) {
    return _favoriteNames.contains(place.displayName);
  }

  Future<void> _toggleFavorite(AiPlaceSuggestion place) async {
    final name = place.displayName;
    setState(() {
      if (_favoriteNames.contains(name)) {
        _favoriteNames.remove(name);
      } else {
        _favoriteNames.add(name);
      }
    });
    await _saveFavorites();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite(place)
              ? t('تمت الإضافة إلى المفضلة', 'Added to favorites')
              : t('تمت الإزالة من المفضلة', 'Removed from favorites'),
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  /// يحدّد نوع المكان من نصّ المستخدم (فنادق / مطاعم / أماكن سياحية)
  String _detectPlaceType(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('hotel') ||
        lower.contains('فنادق') ||
        lower.contains('فندق')) {
      return 'lodging'; // فنادق
    }

    if (lower.contains('restaurant') ||
        lower.contains('مطعم') ||
        lower.contains('أكل') ||
        lower.contains('اكل')) {
      return 'restaurant'; // مطاعم
    }

    // أماكن سياحية عامة
    return 'tourist_attraction';
  }

  /// يكتشف المدينة / المحافظة من النص
  String? _detectCity(String text) {
    final lower = text.toLowerCase();

    final Map<String, List<String>> cityKeywords = {
      'Muscat': ['muscat', 'مسقط'],
      'Sohar': ['sohar', 'صحار'],
      'Salalah': ['salalah', 'صلالة', 'صلاله'],
      'Dhofar': ['dhofar', 'ظفار'],
      'Nizwa': ['nizwa', 'نزوى'],
      'Sur': ['sur', 'صور'],
      'Rustaq': ['rustaq', 'الرستاق'],
      'Barka': ['barka', 'بركاء', 'بركا'],
      'Ibri': ['ibri', 'عبري'],
      'Buraimi': ['buraimi', 'البريمي'],
      'Khasab': ['khasab', 'خصب'],
      'Masirah': ['masirah', 'مصيرة'],
    };

    for (final entry in cityKeywords.entries) {
      for (final kw in entry.value) {
        if (lower.contains(kw)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  /// اختيار صورة: Asset أو Network
  Widget _placeImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _brokenImagePlaceholder(Icons.broken_image),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _brokenImagePlaceholder(Icons.broken_image),
    );
  }

  Widget _brokenImagePlaceholder(IconData icon) {
    return Container(
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: Icon(icon),
    );
  }

  Future<void> _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _loading) return;

    setState(() {
      _loading = true;
      _aiText = null;
      _results = [];
    });

    try {
      final placeType = _detectPlaceType(query);
      final city = _detectCity(query);

      // 1) نسأل Gemini يكتب لنا وصف عام جميل
      final aiResponse = await _ai.sendMessage(query);

      // 2) نجيب البيانات الحقيقية من Firestore
      final places = await _repo.conciergeSearchPlaces(
        placeType: placeType,
        city: city,
      );

      setState(() {
        _aiText = aiResponse;
        _results = places;
        _loading = false;
      });

      _scrollToResults();
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'صار خطأ: $e',
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
        ),
      );
    }
  }

  void _scrollToResults() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFF6F2E7); // خلفية قريبة من قطر
    const accent = Color(0xFF006766); // أخضر مزرق للأزرار

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Al Concierge',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                setState(() => _isArabic = !_isArabic);
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // شريط البحث + زر البحث
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _onSearch(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: t(
                            'أماكن سياحية في ظفار مثلاً…',
                            'E.g. tourist places in Dhofar…',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    onPressed: _onSearch,
                    child: Text(
                      t('بحث', 'Search'),
                      style: const TextStyle(fontFamily: 'Tajawal'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_aiText == null && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            t(
              'اسأليني عن فنادق أو أماكن سياحية في أي ولاية من عُمان ✨',
              'Ask me about hotels or attractions in any city in Oman ✨',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        if (_aiText != null) _AiTextBubble(text: _aiText!),
        const SizedBox(height: 12),
        for (final place in _results)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PlaceCard(
              place: place,
              isFavorite: _isFavorite(place),
              onFavoriteTap: () => _toggleFavorite(place),
              onTap: () {
                // لاحقاً: افتحي شاشة تفاصيل المكان
                // Navigator.push(...);
              },
              imageBuilder: _placeImage,
            ),
          ),
      ],
    );
  }
}

/// فقاعة النص اللي تطلع من Gemini فوق الكروت
class _AiTextBubble extends StatelessWidget {
  final String text;

  const _AiTextBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }
}

/// الكرت اللي يشبه كروت Visit Qatar
class _PlaceCard extends StatelessWidget {
  final AiPlaceSuggestion place;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;
  final Widget Function(String url) imageBuilder;

  const _PlaceCard({
    required this.place,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
    required this.imageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF006766);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF4),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة + أيقونات فوقها
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: imageBuilder(place.imageUrl),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    children: [
                      _roundIconButton(
                        icon: Icons.place_outlined,
                        onTap: () {
                          // لاحقاً: افتحي الخريطة على lat/lng
                        },
                      ),
                      const SizedBox(width: 8),
                      _roundIconButton(
                        icon:
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                        filled: isFavorite,
                        onTap: onFavoriteTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chip للمنطقة
                  if (place.governorate.isNotEmpty ||
                      place.city.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        place.governorate.isNotEmpty
                            ? place.governorate
                            : place.city,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 11,
                          color: accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  Text(
                    place.displayName,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    place.displayDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      TextButton(
                        onPressed: onTap,
                        child: const Text(
                          'Read more',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (place.rating != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              place.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: filled ? Colors.white : Colors.black.withOpacity(0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: filled ? Colors.red : Colors.white,
        ),
      ),
    );
  }
}
