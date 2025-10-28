import 'package:flutter/material.dart';
import '../core/prefs.dart';
import '../core/app_state.dart';

/// شاشة اختيار الموقع والاهتمامات واللغة، ثم الانتقال إلى الصفحة الرئيسية.
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});
  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _useCurrentLocation = false;
  bool _saving = false;
  bool _isArabic = true;
  final Set<String> _interests = <String>{};
  // قائمة الاهتمامات المقترحة
  static const List<String> _options = [
    'تسوق',
    'تاريخ وتراث',
    'شواطئ',
    'طبيعة',
    'مغامرات',
    'مقاهي ومطاعم',
  ];
  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    // اللغة الحالية من Prefs
    final ar = await Prefs.isArabic;
    // الاهتمامات المحفوظة (لو وُجدت)
    final savedInterests = await Prefs.getInterests();
    if (!mounted) return;
    setState(() {
      _isArabic = ar;
      _interests.addAll(savedInterests);
    });
  }

  Future<void> _toggleLanguage() async {
    final app = AppStateProvider.of(context);
    final newCode = _isArabic ? 'en' : 'ar';
    await app.setLanguage(newCode); // يحدّث الـ MaterialApp عبر AppState
    if (!mounted) return;
    setState(() => _isArabic = !_isArabic);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    // 1) حفظ الاهتمامات
    await Prefs.saveInterests(_interests.toList());
    // 2) حفظ الموقع (تبسيطاً: إذا لم يفعّل المستخدم الموقع نضع مسقط)
    if (_useCurrentLocation) {
      // لو عندك خدمة المواقع الخاصة بك استدعيها هنا
      // وإلا سنحفظ إحداثيات لمسقط كقيمة افتراضية
      await Prefs.saveHome(lat: 23.5880, lng: 58.3829, city: 'مسقط');
    } else {
      await Prefs.saveHome(lat: 23.5880, lng: 58.3829, city: 'مسقط');
    }
    // 3) اعتبرنا أن مرحلة Onboarding خلصت
    await Prefs.setOnboardingDone(true);
    if (!mounted) return;
    // 4) الذهاب للصفحة الرئيسية
    Navigator.pushReplacementNamed(context, '/user');
    setState(() => _saving = false);
  }

  Widget _chip(String label) {
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
  }

  @override
  Widget build(BuildContext context) {
    final title = _isArabic ? 'اختيار تفضيلاتك' : 'Choose your preferences';
    final useLoc = _isArabic ? 'استخدم موقعي الحالي' : 'Use current location';
    final interestsTitle = _isArabic ? 'اهتماماتك' : 'Your interests';
    final saveText = _isArabic ? 'ابدأ – تم' : 'Done – Start';
    final langBtn = _isArabic ? 'English' : 'العربية';
    final skip = _isArabic ? 'تخطّي الآن' : 'Skip for now';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _toggleLanguage,
            child: Text(langBtn),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: Text(useLoc),
            value: _useCurrentLocation,
            onChanged: (v) => setState(() => _useCurrentLocation = v),
          ),
          const SizedBox(height: 8),
          Text(interestsTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map(_chip).toList(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator())
                : Text(saveText),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/user'),
            child: Text(skip),
          ),
        ],
      ),
    );
  }
}
