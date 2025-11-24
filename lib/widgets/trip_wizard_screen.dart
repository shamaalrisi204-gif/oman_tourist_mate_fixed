// lib/widgets/trip_wizard_screen.dart

import 'package:flutter/material.dart';

import '../services/recommendations.dart';

import '../models/trip_plan.dart';

/// درافت بسيط نخزن فيه اختيارات المستخدم أثناء الفورم

class _TripDraft {
  String governorate;

  String category; // sea | desert | historic | mountain | ...

  int days;

  int hours;

  bool willBookHere;

  _TripDraft({
    this.governorate = 'muscat',
    this.category = 'sea',
    this.days = 1,
    this.hours = 2,
    this.willBookHere = false,
  });
}

/// شيت تحتّي يظهر فوق الخريطة ويسأل المستخدم عن تفضيلاته

class TripWizardSheet extends StatefulWidget {
  const TripWizardSheet({
    super.key,
    required this.stayCity, // مدينة السكن (مسقط مثلاً)
  });

  final String stayCity;

  @override
  State<TripWizardSheet> createState() => _TripWizardSheetState();
}

class _TripWizardSheetState extends State<TripWizardSheet> {
  final _draft = _TripDraft();

  bool _isArabic = true; // لو حابة تربطيه بحالة التطبيق عدّليه لاحقاً

  // قائمة المحافظات (ممكن تربطيها مع اللي في الخريطة لاحقاً)

  final List<Map<String, String>> _governorates = const [
    {'id': 'muscat', 'ar': 'مسقط', 'en': 'Muscat'},
    {'id': 'dhofar', 'ar': 'ظفار', 'en': 'Dhofar'},
    {'id': 'addakhliyah', 'ar': 'الداخلية', 'en': 'Ad Dakhiliyah'},
    {'id': 'albatinahnorth', 'ar': 'شمال الباطنة', 'en': 'North Al Batinah'},
  ];

  // التصنيفات (نفس اللي في التفضيلات تقريباً)

  final List<Map<String, String>> _categories = const [
    {'id': 'sea', 'ar': 'أماكن بحرية', 'en': 'Sea & beaches'},
    {'id': 'mountain', 'ar': 'أماكن جبلية', 'en': 'Mountains'},
    {'id': 'historic', 'ar': 'أماكن تاريخية', 'en': 'Historic'},
    {'id': 'desert', 'ar': 'أماكن برية/صحراوية', 'en': 'Desert'},
    {'id': 'food', 'ar': 'مطاعم ومقاهي', 'en': 'Food & cafés'},
    {'id': 'hotel', 'ar': 'فنادق', 'en': 'Hotels'},
  ];

  void _confirm() {
    // هنا تجهزين الخطة من التوصيات

    final MapTripPlan plan = Recommendations.buildTrip(
      stayCity: widget.stayCity,

      category: _draft.category,

      placeName: '',

      placeCity: _draft.governorate,

      days: _draft.days,

      hours: _draft.hours,

      etaMinutes: 0, // تربطيها لاحقاً مع المسافة من الخريطة

      willBookHere: _draft.willBookHere,

      suggestedHotel: '',

      suggestedRestaurant: '',
    );

    Navigator.pop(context, plan);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isArabic ? 'إعداد خطة زيارة' : 'Prepare your visit plan';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _isArabic
                  ? 'جاوبي على أسئلة بسيطة، ونجهز لك خطة بناءً على المحافظة والتصنيف وعدد الأيام.'
                  : 'Answer a few quick questions and we\'ll prepare a plan based on governorate, category and duration.',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 20),

            // 1) اختيار المحافظة

            Text(
              _isArabic ? '١. اختاري المحافظة' : '1. Choose a governorate',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _governorates.map((g) {
                  final selected = _draft.governorate == g['id'];

                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(
                        _isArabic ? g['ar']! : g['en']!,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                      selected: selected,
                      selectedColor: const Color(0xFF0057FF),
                      backgroundColor: Colors.grey.shade200,
                      onSelected: (_) {
                        setState(() => _draft.governorate = g['id']!);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // 2) اختيار نوع المكان

            Text(
              _isArabic
                  ? '٢. ما نوع الأماكن اللي تحبي تزوريها؟'
                  : '2. What type of places do you prefer?',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final selected = _draft.category == c['id'];

                return ChoiceChip(
                  label: Text(
                    _isArabic ? c['ar']! : c['en']!,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      color: selected ? Colors.white : Colors.black87,
                    ),
                  ),
                  selected: selected,
                  selectedColor: const Color(0xFF5E2BFF),
                  backgroundColor: Colors.grey.shade200,
                  onSelected: (_) {
                    setState(() => _draft.category = c['id']!);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 3) عدد الأيام

            Text(
              _isArabic ? '٣. مدة الرحلة (أيام)' : '3. Trip duration (days)',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (_draft.days > 1) _draft.days--;
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '${_draft.days}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _draft.days++;
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 4) عدد الساعات في المكان الرئيسي

            Text(
              _isArabic
                  ? '٤. كم ساعة تقريباً في المكان الرئيسي؟'
                  : '4. About how many hours at the main place?',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Slider(
              value: _draft.hours.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${_draft.hours} h',
              onChanged: (v) {
                setState(() => _draft.hours = v.round());
              },
            ),

            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                _isArabic
                    ? '${_draft.hours} ساعة تقريباً'
                    : 'Around ${_draft.hours} hours',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 5) هل بيحجز في نفس المحافظة؟

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isArabic
                        ? 'هل تنوين حجز فندق أو إقامة في هذه المحافظة؟'
                        : 'Do you plan to book a stay in this governorate?',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                    ),
                  ),
                ),
                Switch(
                  value: _draft.willBookHere,
                  onChanged: (v) {
                    setState(() => _draft.willBookHere = v);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0057FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  _isArabic ? 'إنشاء خطتي الآن' : 'Create my trip plan',
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
      ),
    );
  }
}
