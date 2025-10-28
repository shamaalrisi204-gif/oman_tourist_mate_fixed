// lib/screens/onboarding_location_sheet.dart
import 'package:flutter/material.dart';
import '../core/prefs.dart';

class OnboardingLocationSheet extends StatefulWidget {
  const OnboardingLocationSheet({super.key});
  @override
  State<OnboardingLocationSheet> createState() =>
      _OnboardingLocationSheetState();
}

class _OnboardingLocationSheetState extends State<OnboardingLocationSheet> {
  double? _lat;
  double? _lng;
  String? _city;
  final Set<String> _interests = {};
  // اهتمامات جاهزة — عدّليها بحرّيتك
  static const List<String> _options = [
    'تاريخ وتراث',
    'طبيعة',
    'شواطئ',
    'تسوّق',
    'مقاهي ومطاعم',
    'مغامرات',
    'متاحف',
    'تصوير'
  ];
  Future<void> _useCurrentLocation() async {
    // حالياً نضع قيمة افتراضية (مسقط)
    // لاحقاً اربطيها بخدمة الموقع الفعلية لديك.
    setState(() {
      _lat = 23.5880;
      _lng = 58.3829;
      _city = 'Muscat';
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعيين موقعك إلى Muscat (تجريبي)')),
      );
    }
  }

  Future<void> _finish() async {
    if (_lat == null || _lng == null || _city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رجاءً حدّد موقعك أولاً')),
      );
      return;
    }
    await Prefs.saveHome(lat: _lat!, lng: _lng!, city: _city!);
    await Prefs.saveInterests(_interests.toList());
    await Prefs.setOnboardingDone(true);
    if (!mounted) return;
    Navigator.of(context).pop(true); // نرجع للشاشة التي فتحت الشيت
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('لنبدأ رحلتك 🎒', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'حدّد موقعك الحالي لاقتراح خطة قريبة منك، ثم اختر اهتماماتك.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // زر الموقع
            InkWell(
              onTap: _useCurrentLocation,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _city == null
                            ? 'استخدم موقعي الحالي'
                            : 'الموقع: $_city (${_lat!.toStringAsFixed(3)}, ${_lng!.toStringAsFixed(3)})',
                      ),
                    ),
                    if (_city != null) const Icon(Icons.check_circle, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('اهتماماتك', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _options.map((label) {
                final selected = _interests.contains(label);
                return FilterChip(
                  label: Text(label),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _interests.add(label);
                      } else {
                        _interests.remove(label);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _finish,
                child: const Text('ابدأ استكشاف الخريطة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
