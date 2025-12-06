// lib/widgets/trip_wizard_screen.dart

import 'package:flutter/material.dart';
import '../services/recommendations.dart';
import '../models/trip_plan.dart';

/// درافت بسيط نخزن فيه اختيارات المستخدم
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
  bool _isArabic = true;

  // المحافظات
  final List<Map<String, String>> _governorates = const [
    {'id': 'muscat', 'ar': 'مسقط', 'en': 'Muscat'},
    {'id': 'dhofar', 'ar': 'ظفار', 'en': 'Dhofar'},
    {'id': 'addakhliyah', 'ar': 'الداخلية', 'en': 'Ad Dakhiliyah'},
    {'id': 'albatinahnorth', 'ar': 'شمال الباطنة', 'en': 'North Al Batinah'},
  ];

  // التصنيفات
  final List<Map<String, String>> _categories = const [
    {'id': 'sea', 'ar': 'أماكن بحرية', 'en': 'Sea & beaches'},
    {'id': 'mountain', 'ar': 'أماكن جبلية', 'en': 'Mountains'},
    {'id': 'historic', 'ar': 'أماكن تاريخية', 'en': 'Historic'},
    {'id': 'desert', 'ar': 'أماكن صحراوية / برية', 'en': 'Desert'},
    {'id': 'food', 'ar': 'مطاعم ومقاهي', 'en': 'Food & cafés'},
    {'id': 'hotel', 'ar': 'فنادق', 'en': 'Hotels'},
  ];

  void _confirm() {
    /// يبني خطة واحدة من التفضيلات باستخدام TripPlanModel
    final TripPlanModel plan = Recommendations.buildTrip(
      stayCity: widget.stayCity,
      category: _draft.category,
      placeName: '', // ممكن تضيفين لاحقاً اسم المكان من الخريطة أو API
      placeCity: _draft.governorate,
      days: _draft.days,
      hours: _draft.hours,
      etaMinutes: 0,
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
            // السحب من الأعلى
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
                  ? 'جاوبي على أسئلة بسيطة، ونجهز لك خطة كاملة بناءً على اختيارك.'
                  : 'Answer a few questions and we’ll prepare your trip plan.',
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

            // 2) نوع المكان
            Text(
              _isArabic
                  ? '٢. ما نوع الأماكن اللي تحبين زيارتها؟'
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
                  onSelected: (_) => setState(() => _draft.category = c['id']!),
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
                    if (_draft.days > 1) {
                      setState(() => _draft.days--);
                    }
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
                  onPressed: () => setState(() => _draft.days++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 4) ساعات الزيارة
            Text(
              _isArabic
                  ? '٤. كم ساعة تقريباً في المكان؟'
                  : '4. How many hours approximately?',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),

            Slider(
              value: _draft.hours.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '${_draft.hours} h',
              onChanged: (v) => setState(() => _draft.hours = v.round()),
            ),

            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                _isArabic
                    ? '${_draft.hours} ساعة تقريباً'
                    : 'Around ${_draft.hours} hours',
                style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12),
              ),
            ),

            const SizedBox(height: 16),

            // 5) هل يحجز في نفس المحافظة؟
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _isArabic
                        ? 'هل ترغبين بحجز فندق في هذه المحافظة؟'
                        : 'Planning to book a hotel here?',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                    ),
                  ),
                ),
                Switch(
                  value: _draft.willBookHere,
                  onChanged: (v) => setState(() => _draft.willBookHere = v),
                ),
              ],
            ),

            const SizedBox(height: 20),

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
