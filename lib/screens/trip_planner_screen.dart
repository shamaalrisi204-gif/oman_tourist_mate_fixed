// lib/screens/trip_planner_screen.dart

import 'package:flutter/material.dart';

import '../data/tourism_repository.dart';

import '../models/ai_place_suggestion.dart';

import '../models/trip_plan.dart'; // فيه MapTripPlan

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final _repo = TourismRepository.I;

  int _days = 5;

  // المدينة الأساسية (بالعربي عشان تمشي مع CSV)

  String _selectedCity = 'مسقط';

  // نوع الأماكن: general / beach / historic / nature / shopping / adventure

  String _selectedCategoryKey = 'beach';

  bool _loading = false;

  bool _initFromArgs = false;

  List<MapTripPlan> _plan = [];

  // نستقبل قيم من الخريطة (اختياري)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initFromArgs) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      final cat = args['category'] as String?;

      final gov = args['governorate'] as String?;

      if (cat != null) {
        // general / beach / mountain / industrial / historic

        if (cat == 'beach') {
          _selectedCategoryKey = 'beach';
        } else if (cat == 'historic') {
          _selectedCategoryKey = 'historic';
        } else if (cat == 'mountain') {
          _selectedCategoryKey = 'nature';
        } else {
          _selectedCategoryKey = 'general';
        }
      }

      if (gov != null) {
        // نحاول نحول المحافظة/الولاية إلى نفس اسم المدينة في CSV

        if (gov.toLowerCase().contains('muscat')) {
          _selectedCity = 'مسقط';
        } else if (gov.toLowerCase().contains('sohar')) {
          _selectedCity = 'صحار';
        } else if (gov.toLowerCase().contains('salalah')) {
          _selectedCity = 'صلالة';
        } else if (gov.toLowerCase().contains('nizwa')) {
          _selectedCity = 'نزوى';
        }
      }
    }

    _initFromArgs = true;
  }

  // ---------- توليد الخطة من ملفات CSV ----------

  Future<void> _generateTripPlan() async {
    setState(() {
      _loading = true;

      _plan = [];
    });

    try {
      // 1) الأماكن السياحية في المدينة

      final allAttractions = await _repo.searchAttractions(city: _selectedCity);

      List<AiPlaceSuggestion> attractions = allAttractions;

      final key = _selectedCategoryKey;

      if (key == 'beach') {
        attractions = allAttractions
            .where((p) =>
                p.type.toLowerCase().contains('بحر') ||
                p.type.toLowerCase().contains('beach') ||
                p.type.toLowerCase().contains('شاطئ'))
            .toList();
      } else if (key == 'historic') {
        attractions = allAttractions
            .where((p) =>
                p.type.toLowerCase().contains('تاريخ') ||
                p.type.toLowerCase().contains('historic'))
            .toList();
      } else if (key == 'nature') {
        attractions = allAttractions
            .where((p) =>
                p.type.toLowerCase().contains('طبيعة') ||
                p.type.toLowerCase().contains('جبال') ||
                p.type.toLowerCase().contains('mountain') ||
                p.type.toLowerCase().contains('nature'))
            .toList();
      } else if (key == 'shopping') {
        attractions = allAttractions
            .where((p) =>
                p.type.toLowerCase().contains('سوق') ||
                p.type.toLowerCase().contains('تسوق') ||
                p.type.toLowerCase().contains('market') ||
                p.type.toLowerCase().contains('shopping'))
            .toList();
      } else if (key == 'adventure') {
        attractions = allAttractions
            .where((p) =>
                p.type.toLowerCase().contains('مغامرات') ||
                p.type.toLowerCase().contains('adventure'))
            .toList();
      }

      // لو ما لقينا شي في التصنيف نرجّع كل الأماكن

      if (attractions.isEmpty) attractions = allAttractions;

      // 2) فنادق المدينة

      final hotels = await _repo.searchAccommodations(city: _selectedCity);

      // 3) مطاعم/كوفيهات (لو سويتي CSV لها لاحقاً بدلي هذي)

      final restaurants = <AiPlaceSuggestion>[]; // مؤقتاً فاضي

      if (attractions.isEmpty || hotels.isEmpty) {
        setState(() {
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ما حصلت بيانات كافية لهذه المدينة 😢'),
          ),
        );

        return;
      }

      // 4) نبني خطة بسيطة: لكل يوم 2 أماكن + فندق + (مطعم إذا فيه)

      final List<MapTripPlan> plan = [];

      int attrIndex = 0;

      int hotelIndex = 0;

      int restIndex = 0;

      for (int day = 1; day <= _days; day++) {
        for (int i = 0; i < 2; i++) {
          final place = attractions[attrIndex % attractions.length];

          final hotel = hotels[hotelIndex % hotels.length];

          final restaurant = restaurants.isNotEmpty
              ? restaurants[restIndex % restaurants.length]
              : null;

          plan.add(
            MapTripPlan(
              category: key,

              placeName: place.displayName,

              placeCity: place.city,

              stayCity: _selectedCity,

              willBookHere: true,

              days: day,

              hours: 3, // تقدير: 3 ساعات في كل مكان

              etaMinutes: 25, // تقدير وقت الطريق

              suggestedHotel: hotel.displayName,

              suggestedRestaurant: restaurant?.displayName ?? '',
            ),
          );

          attrIndex++;

          hotelIndex++;

          restIndex++;
        }
      }

      setState(() {
        _plan = plan;

        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('صار خطأ في إنشاء الخطة: $e')),
      );
    }
  }

  // ---------- الواجهة ----------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F3E9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F3E9),
          elevation: 0,
          title: const Text(
            'مخطط الرحلات',
            style: TextStyle(fontFamily: 'Tajawal', color: Colors.black),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntroCard(),
              const SizedBox(height: 16),
              _buildDaysPicker(),
              const SizedBox(height: 12),
              _buildCityDropdown(),
              const SizedBox(height: 12),
              _buildCategoryChips(),
              const SizedBox(height: 20),
              _buildGenerateButton(),
              const SizedBox(height: 12),
              _buildPlanSection(),
            ],
          ),
        ),
      ),
    );
  }

  // كرت المقدمة الأخضر

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF008066),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.map, color: Colors.white, size: 26),
          SizedBox(height: 8),
          Text(
            'خطط رحلتك بسهولة ✨',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'اختار المدينة ونوع الأماكن وعدد الأيام، وأنا أرتب لك خطة مرنة وجاهزة.',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // عدد الأيام

  Widget _buildDaysPicker() {
    return Row(
      children: [
        const Text(
          'عدد الأيام',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            if (_days > 1) {
              setState(() => _days--);
            }
          },
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text(
          '$_days',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: () {
            setState(() => _days++);
          },
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
    );
  }

  // اختيار المدينة

  Widget _buildCityDropdown() {
    final cities = ['مسقط', 'صحار', 'صلالة', 'نزوى'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المدينة الأساسية',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCity,
              items: cities
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c,
                        style: const TextStyle(fontFamily: 'Tajawal'),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;

                setState(() => _selectedCity = v);
              },
            ),
          ),
        ),
      ],
    );
  }

  // أزرار أنواع الأماكن

  Widget _buildCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نوع الأماكن',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCategoryChip('beach', 'بحرية'),
            _buildCategoryChip('historic', 'تاريخية'),
            _buildCategoryChip('nature', 'طبيعة'),
            _buildCategoryChip('shopping', 'تسوق'),
            _buildCategoryChip('adventure', 'مغامرات'),
            _buildCategoryChip('general', 'عامّة'),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final selected = _selectedCategoryKey == key;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryKey = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF008066) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFF008066) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  // زر إنشاء الخطة

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _generateTripPlan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008066),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'إنشاء خطة الرحلة ✨',
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 15),
        ),
      ),
    );
  }

  // عرض الخطة

  Widget _buildPlanSection() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_plan.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'ابدأ باختيار مدينة ونوع الأماكن ثم اضغط "إنشاء خطة الرحلة" ✨',
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _plan.length,
      itemBuilder: (context, index) {
        final item = _plan[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اليوم ${item.days} • ${item.placeName}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'المدينة: ${item.placeCity}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'المدة المتوقعة: ${item.hours} ساعات • الطريق تقريباً ${item.etaMinutes} دقيقة',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'فندق مقترح: ${item.suggestedHotel}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                  ),
                ),
                if (item.suggestedRestaurant.isNotEmpty)
                  Text(
                    'مطعم مقترح: ${item.suggestedRestaurant}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
