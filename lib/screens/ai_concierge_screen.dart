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

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isArabic = true;
  bool _loading = false;

  String? _aiText;
  List<AiPlaceSuggestion> _results = [];

  static const _favoritesKey = 'favorites_list_v1';
  final Set<String> _favoriteNames = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
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

  bool _isFavorite(AiPlaceSuggestion p) =>
      _favoriteNames.contains(p.displayName);

  Future<void> _toggleFavorite(AiPlaceSuggestion p) async {
    final name = p.displayName;
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
          _isFavorite(p)
              ? t("تمت الإضافة إلى المفضلة", "Added to favorites")
              : t("تمت الإزالة", "Removed"),
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      ),
    );
  }

  String _detectPlaceType(String text) {
    final l = text.toLowerCase();
    if (l.contains("فندق") || l.contains("hotel")) return "lodging";
    if (l.contains("مطعم") || l.contains("restaurant")) return "restaurant";
    return "tourist_attraction";
  }

  String? _detectCity(String text) {
    final l = text.toLowerCase();
    final mapping = {
      "Muscat": ["muscat", "مسقط"],
      "Salalah": ["salalah", "صلالة", "صلاله"],
      "Nizwa": ["nizwa", "نزوى"],
      "Sohar": ["sohar", "صحار"],
      "Sur": ["sur", "صور"],
      "Dhofar": ["dhofar", "ظفار"],
    };

    for (final entry in mapping.entries) {
      for (final kw in entry.value) {
        if (l.contains(kw)) return entry.key;
      }
    }
    return null;
  }

  Future<void> _onSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _aiText = null;
      _results = [];
    });

    try {
      final type = _detectPlaceType(query);
      final city = _detectCity(query);

      final aiText = await _ai.sendMessage(query);
      final realPlaces = await _repo.conciergeSearchPlaces(
        placeType: type,
        city: city,
      );

      setState(() {
        _aiText = aiText;
        _results = realPlaces;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFF6F2E7);
    const accent = Color(0xFF006766);

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          title: const Text(
            "Al Concierge",
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () => setState(() => _isArabic = !_isArabic),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(accent),
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

  Widget _buildSearchBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: t("ابحث عن أماكن…", "Search a place…"),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _onSearch(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              t("بحث", "Search"),
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_aiText == null && _results.isEmpty) {
      return Center(
        child: Text(
          t("اسألني عن الفنادق أو الأماكن ✨", "Ask me anything ✨"),
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      controller: _scrollController,
      children: [
        if (_aiText != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF4),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              _aiText!,
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        const SizedBox(height: 12),
        for (final p in _results)
          _PlaceCard(
            place: p,
            isFavorite: _isFavorite(p),
            onFavoriteTap: () => _toggleFavorite(p),
            onTap: () {
              final map = {
                "nameAr": p.nameAr,
                "nameEn": p.nameEn,
                "governorate": p.governorate,
                "city": p.city,
                "descriptionArShort": p.descriptionAr,
                "descriptionEnShort": p.descriptionEn,
                "imageUrl": p.imageUrl,
                "rating": p.rating,
                "lat": p.lat,
                "lng": p.lng,
                "isArabic": _isArabic,
              };

              Navigator.pushNamed(
                context,
                "/place_details",
                arguments: map,
              );
            },
          ),
      ],
    );
  }
}

//
// ---------- الكرت ----------
//

class _PlaceCard extends StatelessWidget {
  final AiPlaceSuggestion place;
  final bool isFavorite;
  final VoidCallback onFavoriteTap;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.isFavorite,
    required this.onFavoriteTap,
    required this.onTap,
  });

  // ⭐ دالة جديدة لعرض الصورة من assets أو من النت
  Widget _buildPlaceImage(String url) {
    if (url.startsWith("assets/")) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.broken_image)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF006766);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place.city.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        place.city,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          color: accent,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    place.displayName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    place.displayDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.4,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onTap,
                    child: const Text(
                      "Read more",
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _imageHeader() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: _buildPlaceImage(place.imageUrl), // ⭐ تم التعديل
          ),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: GestureDetector(
            onTap: onFavoriteTap,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.black,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
