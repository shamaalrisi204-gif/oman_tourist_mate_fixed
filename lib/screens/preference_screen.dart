import 'package:flutter/material.dart';
import '../core/prefs.dart';
import '../core/app_state.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

/// موديل interest واحد مع صورة
class _Interest {
  final String id;
  final String titleAr;
  final String titleEn;
  final String imageAsset;

  const _Interest({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.imageAsset,
  });
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  bool _isArabic = true;
  bool _useCurrentLocation = true;

  //  ألوان
  static const Color _primary = Color(0xFF5E2BFF);
  static const Color _background = Color(0xFFF3EED9);

  // كل الاهتمامات (غيري الصور/النص لو حبيتي)
  static const List<_Interest> _allInterests = [
    _Interest(
      id: 'shopping',
      titleAr: 'تسوّق',
      titleEn: 'Shopping',
      imageAsset: 'assets/interests/shopping.jpg',
    ),
    _Interest(
      id: 'heritage',
      titleAr: 'أماكن تراثية وتاريخية',
      titleEn: 'Heritage & history',
      imageAsset: 'assets/interests/heritage.jpg',
    ),
    _Interest(
      id: 'nature',
      titleAr: 'مواقع طبيعية',
      titleEn: 'Nature spots',
      imageAsset: 'assets/interests/nature.jpg',
    ),
    _Interest(
      id: 'beach',
      titleAr: 'شواطئ',
      titleEn: 'Beaches',
      imageAsset: 'assets/interests/beach.jpg',
    ),
    _Interest(
      id: 'adventure',
      titleAr: 'مغامرات',
      titleEn: 'Adventures',
      imageAsset: 'assets/interests/adventure.jpg',
    ),
    _Interest(
      id: 'food',
      titleAr: 'مقاهي ومطاعم',
      titleEn: 'Cafés & restaurants',
      imageAsset: 'assets/interests/food.jpg',
    ),
  ];

  // المختار حالياً
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadLangAndPrefs();
  }

  Future<void> _loadLangAndPrefs() async {
    final ar = await Prefs.isArabic;
    final sp = await Prefs.raw;
    final list = sp.getStringList('user_interests') ?? [];

    if (!mounted) return;

    setState(() {
      _isArabic = ar;
      _selectedIds.addAll(list);
    });
  }

  Future<void> _toggleLanguage() async {
    final app = AppStateProvider.of(context);
    final newCode = _isArabic ? 'en' : 'ar';
    await app.setLanguage(newCode);

    if (!mounted) return;
    setState(() => _isArabic = !_isArabic);
  }

  /// حفظ التفضيلات ثم الذهاب مباشرة لصفحة المستخدم الرئيسية
  Future<void> _saveAndClose() async {
    final sp = await Prefs.raw;
    await sp.setStringList('user_interests', _selectedIds.toList());

    // TODO: هنا لو حابة تحفظين الإحداثيات بناءً على _useCurrentLocation

    if (!mounted) return;

    // بدال Navigator.pop(context);
    Navigator.pushReplacementNamed(context, '/user_home');
  }

  @override
  Widget build(BuildContext context) {
    final title = _isArabic ? 'اختيار تفضيلاتك' : 'Choose your preferences';
    final useLocationLabel =
        _isArabic ? 'استخدم موقعي الحالي' : 'Use my current location';
    final interestsLabel = _isArabic ? 'اهتماماتك' : 'Your interests';
    final startBtn = _isArabic ? 'ابدأ - تم' : 'Done – Start';
    final langBtn = _isArabic ? 'English' : 'العربية';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Tajawal'),
        ),
        actions: [
          TextButton(
            onPressed: _toggleLanguage,
            child: Text(
              langBtn,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // سويتش الموقع
              Row(
                children: [
                  Switch(
                    value: _useCurrentLocation,
                    activeColor: _primary,
                    onChanged: (v) {
                      setState(() => _useCurrentLocation = v);
                      // هنا تقدري تنادي دالة تجيب الإحداثيات وتحفظها في Prefs
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      useLocationLabel,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Text(
                interestsLabel,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // ===== GRID الكروت بالصور =====
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allInterests.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 3 / 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final interest = _allInterests[index];
                  final selected = _selectedIds.contains(interest.id);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedIds.remove(interest.id);
                        } else {
                          _selectedIds.add(interest.id);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected ? _primary : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              interest.imageAsset,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.black.withOpacity(0.05),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 10,
                              child: Text(
                                _isArabic ? interest.titleAr : interest.titleEn,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (selected)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 18,
                                    color: _primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: _saveAndClose,
                  child: Text(
                    startBtn,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
