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

  // ===== Trip Planner =====

  bool _isTripPlan = false;

  List<AiPlaceSuggestion> _hotels = [];

  List<AiPlaceSuggestion> _restaurants = [];

  List<AiPlaceSuggestion> _cafes = [];

  List<AiPlaceSuggestion> _attractions = [];

  // ===== Favorites =====

  static const String _favoritesKey = "favorites_list_v1";

  final Set<String> _favoriteNames = {};

  String t(String ar, String en) {
    return _isArabic ? ar : en;
  }

  @override
  void initState() {
    super.initState();

    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(_favoritesKey) ?? [];

    setState(() {
      _favoriteNames
        ..clear()
        ..addAll(data);
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _favoritesKey,
      _favoriteNames.toList(),
    );
  }

  bool _isFavorite(AiPlaceSuggestion p) {
    return _favoriteNames.contains(p.displayName);
  }

  Future<void> _toggleFavorite(AiPlaceSuggestion p) async {
    setState(() {
      if (_favoriteNames.contains(p.displayName)) {
        _favoriteNames.remove(p.displayName);
      } else {
        _favoriteNames.add(p.displayName);
      }
    });

    await _saveFavorites();
  }

  // ==========================

  // كشف نوع الطلب

  // ==========================

  String _detectPlaceType(String text) {
    final l = text.toLowerCase();

    if (l.contains("hotel") || l.contains("فندق")) {
      return "lodging";
    }

    if (l.contains("restaurant") || l.contains("مطعم")) {
      return "restaurant";
    }

    return "tourist_attraction";
  }

  String? _detectCity(String text) {
    final l = text.toLowerCase();

    if (l.contains("muscat") || l.contains("مسقط")) {
      return "مسقط";
    }

    if (l.contains("salalah") || l.contains("صلالة")) {
      return "صلالة";
    }

    if (l.contains("sohar") || l.contains("صحار")) {
      return "صحار";
    }

    if (l.contains("nizwa") || l.contains("نزوى")) {
      return "نزوى";
    }

    return null;
  }
  // ==========================

// Trip Planner Detection

// ==========================

  bool _isTripRequest(String text) {
    final l = text.toLowerCase();

    return l.contains("جدول") ||
        l.contains("برنامج") ||
        l.contains("رحلة") ||
        l.contains("خطة") ||
        l.contains("itinerary") ||
        l.contains("trip");
  }

  int _detectDays(String text) {
    final number = RegExp(r'\d+').firstMatch(text);

    if (number != null) {
      return int.tryParse(number.group(0)!) ?? 1;
    }

    if (text.contains("يومين")) return 2;

    if (text.contains("ثلاث")) return 3;

    if (text.contains("أسبوع")) return 7;

    return 1;
  }

// ==========================

// Create Trip Plan Text

// ==========================

  String _createTripPlanText(String? city, int days) {
    String plan = "✨ جدول سياحي في ${city ?? ""}\n"
        "🗓️ المدة: $days أيام\n\n";

// الفندق

    if (_hotels.isNotEmpty) {
      plan += "🏨 الفندق المقترح:\n"
          "• ${_hotels.first.displayName}\n\n";
    }

    int attractionIndex = 0;

    for (int day = 1; day <= days; day++) {
      plan += "━━━━━━━━━━━━\n"
          "📅 اليوم $day\n\n";

      plan += "🌅 الصباح:\n";

      for (int i = 0; i < 2; i++) {
        if (attractionIndex < _attractions.length) {
          plan += "📍 ${_attractions[attractionIndex].displayName}\n";

          attractionIndex++;
        }
      }

// مطعم

      if (_restaurants.isNotEmpty) {
        plan += "\n🍽 الغداء:\n"
            "• ${_restaurants[day % _restaurants.length].displayName}\n";
      }

// كوفي

      if (_cafes.isNotEmpty) {
        plan += "\n☕ القهوة:\n"
            "• ${_cafes[day % _cafes.length].displayName}\n";
      }

      plan += "\n";
    }

    return plan;
  }

  Future<void> _onSearch() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) return;

    setState(() {
      _loading = true;

      _aiText = null;

      _results = [];

      _isTripPlan = false;
    });

    try {
      final city = _detectCity(query);

      final isTrip = _isTripRequest(query);

// =====================

// Trip Planner

// =====================

      if (isTrip) {
        _hotels = await _repo.searchAccommodations(city: city);

        _attractions = await _repo.searchAttractions(city: city);

        _restaurants = await _repo.searchRestaurants(city: city);

        _cafes = await _repo.searchCafes(city: city);

        _isTripPlan = true;

        _aiText = _createTripPlanText(city, _detectDays(query));

// الكروت التي ستظهر تحت الجدول

        _results = [
          ..._hotels.take(1),
          ..._attractions,
          ..._restaurants.take(3),
          ..._cafes.take(3),
        ];
      } else {
// =====================

// البحث العادي

// =====================

        final answer = await _ai.sendMessage(query);

        _results = await _repo.conciergeSearchPlaces(
          placeType: _detectPlaceType(query),
          city: city,
        );

        _aiText = answer;
      }

      setState(() {
        _loading = false;
      });
    } catch (e, st) {
      print("ERROR : $e\n$st");

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("حدث خطأ: $e"),
        ),
      );
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
            "AI Concierge",
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.language),
              onPressed: () {
                setState(() {
                  _isArabic = !_isArabic;
                });
              },
            )
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(accent),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _buildContent(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(Color accent) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: t("ابحث عن رحلة...", "Search..."),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _onSearch(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _onSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
            ),
            child: Text(t("بحث", "Search")),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_aiText == null && _results.isEmpty) {
      return Center(
        child: Text(
          t("اسألني عن رحلتك ✨", "Ask me anything ✨"),
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
// الجدول أو جواب AI

        if (_aiText != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _aiText!,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ),

        const SizedBox(height: 15),

        for (final p in _results)
          _PlaceCard(
            place: p,
            isFavorite: _isFavorite(p),
            onFavoriteTap: () {
              _toggleFavorite(p);
            },
            onTap: () {
              Navigator.pushNamed(
                context,
                "/place_details",
                arguments: {
                  "nameAr": p.nameAr,
                  "nameEn": p.nameEn,
                  "city": p.city,
                  "descriptionArShort": p.descriptionAr,
                  "descriptionEnShort": p.descriptionEn,
                  "imageUrl": p.imageUrl,
                  "rating": p.rating,
                  "lat": p.lat,
                  "lng": p.lng,
                },
              );
            },
          ),
      ],
    );
  }
}

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

  String _getType() {
    final type = place.type.toLowerCase();

    if (type.contains("hotel") || type.contains("resort")) {
      return "🏨 فندق";
    }

    if (type.contains("restaurant")) {
      return "🍽 مطعم";
    }

    if (type.contains("cafe")) {
      return "☕ كوفي";
    }

    return "📍 مكان سياحي";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
              )
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE

            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.asset(
                place.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.image,
                      size: 50,
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          place.displayName,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Tajawal"),
                        ),
                      ),
                      IconButton(
                        onPressed: onFavoriteTap,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 8),

                  // TYPE

                  Text(
                    _getType(),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // RATING

                  if (place.rating != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          place.rating.toString(),
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        )
                      ],
                    ),

                  const SizedBox(height: 10),

                  // CITY

                  Text(
                    "📍 ${place.city ?? ""}",
                    style: const TextStyle(
                      fontFamily: "Tajawal",
                    ),
                  ),

                  const SizedBox(height: 10),

                  // DESCRIPTION

                  Text(
                    place.descriptionAr ?? "",
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      height: 1.5,
                      fontFamily: "Tajawal",
                      color: Colors.black87,
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
}
